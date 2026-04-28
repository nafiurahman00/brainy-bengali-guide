import { createClient, SupabaseClient } from "@supabase/supabase-js";

let _service: SupabaseClient | null = null;
let _anon: SupabaseClient | null = null;

/** Service-role client. Bypasses RLS — only use on the server, never echo to clients. */
export function serviceClient(): SupabaseClient {
  if (_service) return _service;
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required");
  _service = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return _service;
}

/** Anon client — used to verify JWTs via supabase.auth.getUser(jwt). */
export function anonClient(): SupabaseClient {
  if (_anon) return _anon;
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_ANON_KEY;
  if (!url || !key) throw new Error("SUPABASE_URL and SUPABASE_ANON_KEY are required");
  _anon = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return _anon;
}
