// Edge Function: create-donation
// Dipanggil aplikasi Flutter: Supabase.instance.client.functions.invoke('create-donation', body: {...})
// Alur: cek pengguna -> RPC create_donation (validasi di database) -> buat transaksi Midtrans Snap
//       -> simpan snap_token dan redirect_url -> kembalikan redirect_url ke aplikasi.
import { createClient } from "npm:@supabase/supabase-js@2";
import {
  corsHeaders,
  json,
  midtransServerKey,
  publishableKey,
  secretKey,
  snapBaseUrl,
  supabaseUrl,
} from "../_shared/env.ts";

const EXPIRY_HOURS = 24;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Metode tidak didukung" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Silakan masuk terlebih dahulu" }, 401);

  // Klien dengan JWT pengguna: RLS dan auth.uid() berlaku.
  const userClient = createClient(supabaseUrl(), publishableKey(), {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );
  if (userError || !userData.user) return json({ error: "Sesi tidak valid, silakan masuk ulang" }, 401);

  let body: { campaign_id?: string; amount?: number; is_anonymous?: boolean; message?: string };
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "Data tidak valid" }, 400);
  }
  if (!body.campaign_id || typeof body.amount !== "number") {
    return json({ error: "campaign_id dan amount wajib diisi" }, 400);
  }

  // 1. Buat donasi + transaksi pending. Semua aturan (akun ITS, minimal Rp5.000,
  //    kampanye aktif, tenggat) diperiksa di fungsi database.
  const { data: rows, error: rpcError } = await userClient.rpc("create_donation", {
    p_campaign_id: body.campaign_id,
    p_amount: Math.trunc(body.amount),
    p_is_anonymous: body.is_anonymous ?? false,
    p_message: body.message ?? null,
  });
  if (rpcError || !rows || rows.length === 0) {
    return json({ error: rpcError?.message ?? "Donasi gagal dibuat" }, 400);
  }
  const donation = rows[0] as { donation_id: string; order_id: string; gross_amount: number };

  const admin = createClient(supabaseUrl(), secretKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const [{ data: campaign }, { data: profile }] = await Promise.all([
    admin.from("campaigns").select("title").eq("id", body.campaign_id).single(),
    admin.from("profiles").select("full_name").eq("id", userData.user.id).single(),
  ]);

  // 2. Buat transaksi Snap.
  const grossAmount = Number(donation.gross_amount);
  const finishUrl = Deno.env.get("MIDTRANS_FINISH_URL");
  const snapBody: Record<string, unknown> = {
    transaction_details: { order_id: donation.order_id, gross_amount: grossAmount },
    item_details: [{
      id: body.campaign_id.slice(0, 50),
      price: grossAmount,
      quantity: 1,
      name: `Donasi ${campaign?.title ?? "ITSbisa"}`.slice(0, 50),
    }],
    customer_details: {
      first_name: (profile?.full_name ?? "Donatur ITS").slice(0, 50),
      email: userData.user.email,
    },
    expiry: { unit: "hours", duration: EXPIRY_HOURS },
  };
  if (finishUrl) snapBody.callbacks = { finish: finishUrl };

  let snap: { token?: string; redirect_url?: string; error_messages?: string[] };
  try {
    const res = await fetch(`${snapBaseUrl()}/snap/v1/transactions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization: `Basic ${btoa(`${midtransServerKey()}:`)}`,
      },
      body: JSON.stringify(snapBody),
    });
    snap = await res.json();
    if (!res.ok || !snap.token || !snap.redirect_url) {
      throw new Error(snap.error_messages?.join(", ") ?? `HTTP ${res.status}`);
    }
  } catch (e) {
    // Transaksi tidak jadi dibuat di Midtrans: tandai gagal supaya tidak menggantung.
    await admin.from("payment_transactions").update({ status: "failure" }).eq("order_id", donation.order_id);
    await admin.from("donations").update({ status: "failed" }).eq("id", donation.donation_id);
    console.error("Midtrans Snap error", e);
    return json({ error: "Gagal menghubungi Midtrans. Coba lagi." }, 502);
  }

  // 3. Simpan token agar pembayaran bisa dilanjutkan dari Riwayat.
  const expiry = new Date(Date.now() + EXPIRY_HOURS * 60 * 60 * 1000).toISOString();
  await admin
    .from("payment_transactions")
    .update({ snap_token: snap.token, redirect_url: snap.redirect_url, expiry_time: expiry })
    .eq("order_id", donation.order_id);

  return json({
    donation_id: donation.donation_id,
    order_id: donation.order_id,
    snap_token: snap.token,
    redirect_url: snap.redirect_url,
  });
});
