import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import {
  authenticatedUser,
  BILLING_PLANS,
  canManageRing,
  jsonResponse,
  stripeRequest,
} from "../_shared/stripe.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type CheckoutSession = {
  id: string;
  url: string | null;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "method not allowed" }, {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    const user = await authenticatedUser(req);
    const body = await req.json();
    const ringId = String(body.ring_id ?? body.ringId ?? "");
    const planKey = String(body.plan ?? "");
    const plan = BILLING_PLANS[planKey];

    if (!ringId || !plan) {
      return jsonResponse({ ok: false, error: "invalid ring or plan" }, {
        status: 400,
        headers: corsHeaders,
      });
    }

    if (!await canManageRing(ringId, user.id)) {
      return jsonResponse({ ok: false, error: "not allowed" }, {
        status: 403,
        headers: corsHeaders,
      });
    }

    const priceId = Deno.env.get(plan.priceEnv);
    if (!priceId) {
      return jsonResponse({ ok: false, error: `missing ${plan.priceEnv}` }, {
        status: 500,
        headers: corsHeaders,
      });
    }

    const successURL = Deno.env.get("STRIPE_SUCCESS_URL");
    const cancelURL = Deno.env.get("STRIPE_CANCEL_URL");
    if (!successURL || !cancelURL) {
      return jsonResponse({ ok: false, error: "missing checkout return URLs" }, {
        status: 500,
        headers: corsHeaders,
      });
    }

    const params = new URLSearchParams();
    params.set("mode", plan.mode);
    params.set("success_url", successURL);
    params.set("cancel_url", cancelURL);
    params.set("client_reference_id", ringId);
    params.set("line_items[0][price]", priceId);
    params.set("line_items[0][quantity]", "1");
    params.set("metadata[ring_id]", ringId);
    params.set("metadata[payer_id]", user.id);
    params.set("metadata[plan]", plan.key);

    if (plan.mode === "subscription") {
      params.set("subscription_data[metadata][ring_id]", ringId);
      params.set("subscription_data[metadata][payer_id]", user.id);
      params.set("subscription_data[metadata][plan]", plan.key);
    } else {
      params.set("payment_intent_data[metadata][ring_id]", ringId);
      params.set("payment_intent_data[metadata][payer_id]", user.id);
      params.set("payment_intent_data[metadata][plan]", plan.key);
    }

    const session = await stripeRequest<CheckoutSession>(
      "checkout/sessions",
      params,
    );

    return jsonResponse({
      ok: true,
      sessionId: session.id,
      url: session.url,
      plan: plan.key,
    }, { headers: corsHeaders });
  } catch (error) {
    return jsonResponse({
      ok: false,
      error: error instanceof Error ? error.message : "checkout failed",
    }, {
      status: 400,
      headers: corsHeaders,
    });
  }
});
