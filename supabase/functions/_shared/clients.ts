// Shared Supabase + Stripe clients for the campaign payment functions.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

export const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
export const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
export const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

export const STRIPE_PUBLISHABLE_KEY = Deno.env.get("STRIPE_PUBLISHABLE_KEY") ?? "";

// Platform fee: basis points of the donation + an optional fixed amount.
// e.g. HALO_APPLICATION_FEE_BPS=500 -> 5%.
const FEE_BPS = Number(Deno.env.get("HALO_APPLICATION_FEE_BPS") ?? "500");
const FEE_FIXED_CENTS = Number(Deno.env.get("HALO_APPLICATION_FEE_FIXED_CENTS") ?? "0");

export function applicationFee(amountCents: number): number {
  const fee = Math.floor((amountCents * FEE_BPS) / 10000) + FEE_FIXED_CENTS;
  // Never let the fee meet or exceed the donation.
  return Math.max(0, Math.min(fee, amountCents - 1));
}

/** Service-role client: bypasses RLS. Used for all writes. */
export function adminClient() {
  return createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false },
  });
}

export const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

export const cryptoProvider = Stripe.createSubtleCryptoProvider();

/** Resolve the caller's user id from the bearer token, or null if anonymous. */
export async function userFromRequest(req: Request): Promise<string | null> {
  const auth = req.headers.get("Authorization");
  if (!auth) return null;
  const token = auth.replace("Bearer ", "").trim();
  if (!token) return null;
  const supa = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false },
  });
  const { data, error } = await supa.auth.getUser();
  if (error || !data.user) return null;
  return data.user.id;
}
