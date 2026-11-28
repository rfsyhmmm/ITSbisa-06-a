// Edge Function: midtrans-notification
// Diisi sebagai "Payment Notification URL" di Dashboard Midtrans Sandbox:
//   https://<project-ref>.supabase.co/functions/v1/midtrans-notification
// Alur: cek signature_key -> ambil status resmi dari API Midtrans -> RPC apply_payment_notification.
import { createClient } from "npm:@supabase/supabase-js@2";
import { coreApiBaseUrl, json, midtransServerKey, secretKey, supabaseUrl } from "../_shared/env.ts";

async function sha512(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-512", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Metode tidak didukung" }, 405);

  let payload: Record<string, string>;
  try {
    payload = await req.json();
  } catch (_) {
    return json({ error: "Payload tidak valid" }, 400);
  }

  const { order_id, status_code, gross_amount, signature_key } = payload;
  if (!order_id || !status_code || !gross_amount || !signature_key) {
    return json({ error: "Field notifikasi tidak lengkap" }, 400);
  }

  // 1. signature_key = SHA512(order_id + status_code + gross_amount + ServerKey)
  const serverKey = midtransServerKey();
  const expected = await sha512(order_id + status_code + gross_amount + serverKey);
  if (expected !== signature_key) return json({ error: "Signature tidak valid" }, 403);

  // Notifikasi uji dari dashboard Midtrans memakai order_id acak: abaikan dengan 200.
  if (!order_id.startsWith("ITSB-")) return json({ result: "ignored" });

  // 2. Ambil status resmi langsung dari Midtrans (tidak hanya percaya isi notifikasi).
  const statusRes = await fetch(`${coreApiBaseUrl()}/v2/${encodeURIComponent(order_id)}/status`, {
    headers: { Accept: "application/json", Authorization: `Basic ${btoa(`${serverKey}:`)}` },
  });
  const status = await statusRes.json();
  if (!statusRes.ok || !status.transaction_status) {
    console.error("Status Midtrans gagal diambil", status);
    return json({ error: "Status transaksi tidak dapat diperiksa" }, 502); // Midtrans akan mengirim ulang
  }

  // 3. Terapkan ke database secara idempoten.
  const admin = createClient(supabaseUrl(), secretKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await admin.rpc("apply_payment_notification", {
    p_payload: {
      order_id,
      transaction_status: status.transaction_status,
      fraud_status: status.fraud_status ?? null,
      gross_amount: status.gross_amount ?? gross_amount,
      payment_type: status.payment_type ?? payload.payment_type ?? null,
      transaction_id: status.transaction_id ?? null,
      status_code: status.status_code ?? status_code,
      received_at: new Date().toISOString(),
    },
  });
  if (error) {
    console.error("apply_payment_notification gagal", error);
    return json({ error: error.message }, 500); // Midtrans akan mencoba lagi
  }
  return json({ result: data });
});
