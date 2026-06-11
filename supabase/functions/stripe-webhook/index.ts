// stripe-webhook
// Confirms donation outcomes from Stripe and keeps Connect account status in
// sync. This is the ONLY path that flips a contribution to 'paid' — clients can
// never do it — so campaign totals (maintained by a DB trigger) can't be forged.
//
// Configure a *Connect* webhook in Stripe pointing here, subscribed to:
//   payment_intent.succeeded, payment_intent.payment_failed,
//   payment_intent.canceled, charge.refunded, account.updated,
//   checkout.session.completed, checkout.session.expired

import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { adminClient, cryptoProvider, stripe } from "../_shared/clients.ts";

const WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const signature = req.headers.get("stripe-signature");
  if (!signature) return jsonResponse({ error: "missing_signature" }, 400);

  const payload = await req.text();
  let event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      payload,
      signature,
      WEBHOOK_SECRET,
      undefined,
      cryptoProvider,
    );
  } catch (e) {
    return jsonResponse({ error: `invalid_signature: ${(e as Error).message}` }, 400);
  }

  const supa = adminClient();

  try {
    switch (event.type) {
      case "payment_intent.succeeded": {
        const pi = event.data.object as { id: string };
        await setContributionStatus(supa, pi.id, "paid");
        break;
      }
      case "checkout.session.completed": {
        // Web donations are tracked by the Checkout Session id.
        const session = event.data.object as { id: string; payment_status: string };
        if (session.payment_status === "paid") {
          await setContributionStatus(supa, session.id, "paid");
        }
        break;
      }
      case "checkout.session.expired": {
        const session = event.data.object as { id: string };
        await setContributionStatus(supa, session.id, "failed");
        break;
      }
      case "payment_intent.payment_failed":
      case "payment_intent.canceled": {
        const pi = event.data.object as { id: string };
        await setContributionStatus(supa, pi.id, "failed");
        break;
      }
      case "charge.refunded": {
        const charge = event.data.object as { payment_intent: string | null };
        if (charge.payment_intent) {
          await setContributionStatus(supa, charge.payment_intent, "refunded");
        }
        break;
      }
      case "account.updated": {
        const account = event.data.object as {
          id: string;
          charges_enabled: boolean;
          payouts_enabled: boolean;
          details_submitted: boolean;
        };
        await supa
          .from("stripe_accounts")
          .update({
            charges_enabled: account.charges_enabled,
            payouts_enabled: account.payouts_enabled,
            details_submitted: account.details_submitted,
          })
          .eq("stripe_account_id", account.id);
        break;
      }
      default:
        break;
    }
  } catch (e) {
    return jsonResponse({ error: String((e as Error)?.message ?? e) }, 500);
  }

  return jsonResponse({ received: true });
});

async function setContributionStatus(
  supa: ReturnType<typeof adminClient>,
  paymentIntentId: string,
  status: "paid" | "failed" | "refunded",
) {
  await supa
    .from("campaign_contributions")
    .update({ status })
    .eq("provider_payment_id", paymentIntentId);
}
