// campaign-connect-onboard
// Creates (or reuses) the caller's Stripe Connect Express account and returns a
// fresh onboarding account link. The creator must finish onboarding before their
// campaigns can receive donations. Requires a valid Supabase JWT.

import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { adminClient, stripe, userFromRequest } from "../_shared/clients.ts";

const RETURN_URL = Deno.env.get("STRIPE_CONNECT_RETURN_URL") ?? "halo://campaign/connect/return";
const REFRESH_URL = Deno.env.get("STRIPE_CONNECT_REFRESH_URL") ?? "halo://campaign/connect/refresh";

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const userId = await userFromRequest(req);
    if (!userId) return jsonResponse({ error: "unauthorized" }, 401);

    const supa = adminClient();

    const { data: existing } = await supa
      .from("stripe_accounts")
      .select("stripe_account_id")
      .eq("user_id", userId)
      .maybeSingle();

    let accountId: string | undefined = existing?.stripe_account_id;

    if (!accountId) {
      const account = await stripe.accounts.create({
        type: "express",
        business_type: "individual",
        capabilities: {
          transfers: { requested: true },
          card_payments: { requested: true },
        },
        metadata: { halo_user_id: userId },
      });
      accountId = account.id;
      await supa.from("stripe_accounts").upsert({
        user_id: userId,
        stripe_account_id: accountId,
        charges_enabled: account.charges_enabled,
        payouts_enabled: account.payouts_enabled,
        details_submitted: account.details_submitted,
      });
    }

    const link = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: REFRESH_URL,
      return_url: RETURN_URL,
      type: "account_onboarding",
    });

    return jsonResponse({ url: link.url, accountId });
  } catch (e) {
    return jsonResponse({ error: String((e as Error)?.message ?? e) }, 500);
  }
});
