// campaign-create-payment
// Creates a Stripe PaymentIntent as a *direct charge* on the campaign creator's
// connected account (funds go straight to them) with Halo's application fee, and
// records a pending contribution. Returns the client secret for PaymentSheet.
//
// verify_jwt is false so non-Halo web donors can give too; if a valid bearer
// token is present the contribution is attributed to that user.

import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  adminClient,
  applicationFee,
  STRIPE_PUBLISHABLE_KEY,
  stripe,
  userFromRequest,
} from "../_shared/clients.ts";

interface PaymentRequest {
  campaignId: string;
  amountCents: number;
  displayName?: string;
  message?: string;
  isAnonymous?: boolean;
  idempotencyKey?: string;
}

const MIN_AMOUNT_CENTS = 50;

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const body = (await req.json()) as PaymentRequest;
    const amount = Math.floor(Number(body.amountCents));
    if (!body.campaignId || !Number.isFinite(amount) || amount < MIN_AMOUNT_CENTS) {
      return jsonResponse({ error: "invalid_amount" }, 400);
    }

    const userId = await userFromRequest(req);
    const supa = adminClient();

    const { data: campaign, error: campErr } = await supa
      .from("campaigns")
      .select("id, creator_id, currency, status, expires_at, title")
      .eq("id", body.campaignId)
      .single();

    if (campErr || !campaign) return jsonResponse({ error: "campaign_not_found" }, 404);
    if (campaign.status !== "active") return jsonResponse({ error: "campaign_closed" }, 409);
    if (campaign.expires_at && new Date(campaign.expires_at) <= new Date()) {
      return jsonResponse({ error: "campaign_expired" }, 409);
    }

    const { data: account } = await supa
      .from("stripe_accounts")
      .select("stripe_account_id, charges_enabled")
      .eq("user_id", campaign.creator_id)
      .maybeSingle();

    if (!account?.stripe_account_id || !account.charges_enabled) {
      return jsonResponse({ error: "creator_not_onboarded" }, 409);
    }

    const fee = applicationFee(amount);
    const idempotencyKey = body.idempotencyKey ?? crypto.randomUUID();

    const intent = await stripe.paymentIntents.create(
      {
        amount,
        currency: campaign.currency ?? "eur",
        application_fee_amount: fee,
        automatic_payment_methods: { enabled: true },
        metadata: {
          halo_campaign_id: campaign.id,
          halo_user_id: userId ?? "",
        },
      },
      {
        stripeAccount: account.stripe_account_id,
        idempotencyKey,
      },
    );

    const { error: insErr } = await supa.from("campaign_contributions").insert({
      campaign_id: campaign.id,
      contributor_id: userId,
      display_name: body.isAnonymous ? null : (body.displayName ?? null),
      message: body.message ?? null,
      amount_cents: amount,
      application_fee_cents: fee,
      currency: campaign.currency ?? "eur",
      provider: "stripe",
      provider_payment_id: intent.id,
      status: "pending",
      is_anonymous: body.isAnonymous ?? false,
    });

    if (insErr) return jsonResponse({ error: insErr.message }, 500);

    return jsonResponse({
      clientSecret: intent.client_secret,
      publishableKey: STRIPE_PUBLISHABLE_KEY,
      connectedAccountId: account.stripe_account_id,
      paymentIntentId: intent.id,
    });
  } catch (e) {
    return jsonResponse({ error: String((e as Error)?.message ?? e) }, 500);
  }
});
