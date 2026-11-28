// Membaca kunci Supabase dari environment Edge Function.
// Mendukung kunci baru (SUPABASE_PUBLISHABLE_KEYS / SUPABASE_SECRET_KEYS)
// dan kunci lama (SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY).

function readKey(jsonName: string, legacyName: string): string {
  const raw = Deno.env.get(jsonName);
  if (raw) {
    try {
      const keys = JSON.parse(raw) as Record<string, string>;
      if (keys["default"]) return keys["default"];
    } catch (_) {
      // Lanjut ke kunci lama.
    }
  }
  const legacy = Deno.env.get(legacyName);
  if (!legacy) throw new Error(`Kunci ${jsonName} / ${legacyName} tidak ditemukan`);
  return legacy;
}

export const supabaseUrl = () => Deno.env.get("SUPABASE_URL")!;
export const publishableKey = () => readKey("SUPABASE_PUBLISHABLE_KEYS", "SUPABASE_ANON_KEY");
export const secretKey = () => readKey("SUPABASE_SECRET_KEYS", "SUPABASE_SERVICE_ROLE_KEY");

export function midtransServerKey(): string {
  const key = Deno.env.get("MIDTRANS_SERVER_KEY");
  if (!key) throw new Error("Secret MIDTRANS_SERVER_KEY belum diisi");
  return key;
}

const isProduction = () => Deno.env.get("MIDTRANS_IS_PRODUCTION") === "true";
export const snapBaseUrl = () =>
  isProduction() ? "https://app.midtrans.com" : "https://app.sandbox.midtrans.com";
export const coreApiBaseUrl = () =>
  isProduction() ? "https://api.midtrans.com" : "https://api.sandbox.midtrans.com";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
