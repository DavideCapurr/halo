import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import {
  authenticatedUser,
  canManageRing,
  jsonResponse,
  serviceClient,
  stripeRequest,
} from "../_shared/stripe.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type PortalSession = {
  id: string;
  url: string;
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
    const suppliedCustomer = String(body.stripe_customer_id ?? body.customer ?? "");

    if (!ringId) {
      return jsonResponse({ ok: false, error: "missing ring" }, {
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

    const customer = await resolveStripeCustomer(ringId, user.id, suppliedCustomer);
    if (!customer) {
      return jsonResponse({ ok: false, error: "missing stripe customer" }, {
        status: 404,
        headers: corsHeaders,
      });
    }

    const returnURL = Deno.env.get("STRIPE_PORTAL_RETURN_URL") ??
      Deno.env.get("STRIPE_SUCCESS_URL");
    if (!returnURL) {
      return jsonResponse({ ok: false, error: "missing portal return URL" }, {
        status: 500,
        headers: corsHeaders,
      });
    }

    const params = new URLSearchParams();
    params.set("customer", customer);
    params.set("return_url", returnURL);

    const session = await stripeRequest<PortalSession>(
      "billing_portal/sessions",
      params,
    );
    return jsonResponse({ ok: true, id: session.id, url: session.url }, {
      headers: corsHeaders,
    });
  } catch (error) {
    return jsonResponse({
      ok: false,
      error: error instanceof Error ? error.message : "portal failed",
    }, {
      status: 400,
      headers: corsHeaders,
    });
  }
});

async function resolveStripeCustomer(
  ringId: string,
  userId: string,
  suppliedCustomer: string,
): Promise<string | null> {
  const supa = serviceClient();
  let subscriptionQuery = supa
    .from("subscriptions")
    .select("provider_customer_id")
    .eq("provider", "stripe")
    .eq("ring_id", ringId)
    .eq("user_id", userId);
  subscriptionQuery = suppliedCustomer.length > 0
    ? subscriptionQuery.eq("provider_customer_id", suppliedCustomer)
    : subscriptionQuery.not("provider_customer_id", "is", null);

  const { data: subscription, error: subscriptionError } = await subscriptionQuery
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (subscriptionError) throw new Error(subscriptionError.message);
  if (subscription?.provider_customer_id) return subscription.provider_customer_id;

  let billingQuery = supa
    .from("club_billing")
    .select("provider_customer_id")
    .eq("provider", "stripe")
    .eq("ring_id", ringId)
    .eq("payer_id", userId);
  billingQuery = suppliedCustomer.length > 0
    ? billingQuery.eq("provider_customer_id", suppliedCustomer)
    : billingQuery.not("provider_customer_id", "is", null);

  const { data: billing, error: billingError } = await billingQuery
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (billingError) throw new Error(billingError.message);
  return billing?.provider_customer_id ?? null;
}
