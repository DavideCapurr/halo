import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import {
  BILLING_PLANS,
  isoFromSeconds,
  jsonResponse,
  numberValue,
  stringValue,
  upsertBilling,
  upsertSubscription,
  verifyStripeSignature,
} from "../_shared/stripe.ts";

type StripeEvent = {
  id: string;
  type: string;
  data: { object: Record<string, unknown> };
};

serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "method not allowed" }, { status: 405 });
  }

  const rawBody = await req.text();
  try {
    await verifyStripeSignature(rawBody, req.headers.get("Stripe-Signature"));
    const event = JSON.parse(rawBody) as StripeEvent;
    await handleStripeEvent(event);
    return jsonResponse({ ok: true, eventId: event.id, type: event.type });
  } catch (error) {
    return jsonResponse({
      ok: false,
      error: error instanceof Error ? error.message : "stripe webhook failed",
    }, { status: 400 });
  }
});

async function handleStripeEvent(event: StripeEvent) {
  const object = event.data.object;
  switch (event.type) {
    case "checkout.session.completed":
    case "checkout.session.async_payment_succeeded":
      await handleCheckoutSession(object);
      break;
    case "customer.subscription.created":
    case "customer.subscription.updated":
    case "customer.subscription.deleted":
      await handleSubscription(object);
      break;
    case "invoice.payment_succeeded":
      await handleInvoice(object, "paid");
      break;
    case "invoice.payment_failed":
      await handleInvoice(object, "failed");
      break;
    default:
      break;
  }
}

async function handleCheckoutSession(session: Record<string, unknown>) {
  const metadata = metadataFrom(session);
  const ringId = metadata.ring_id;
  const payerId = metadata.payer_id;
  const planKey = metadata.plan;
  if (!ringId || !payerId || !planKey) return;

  const sessionId = stringValue(session.id);
  const subscriptionId = stringValue(session.subscription);
  const mode = stringValue(session.mode);
  const amount = numberValue(session.amount_total) ??
    BILLING_PLANS[planKey]?.amountCents ?? 0;
  const currency = stringValue(session.currency) ?? "eur";
  const paymentStatus = stringValue(session.payment_status);

  if (subscriptionId) {
    await upsertSubscription({
      ring_id: ringId,
      user_id: payerId,
      provider_subscription_id: subscriptionId,
      status: paymentStatus === "paid" ? "active" : "incomplete",
      plan: planKey,
      metadata: { checkout_session_id: sessionId, mode },
    });
  } else if (sessionId) {
    await upsertSubscription({
      ring_id: ringId,
      user_id: payerId,
      provider_subscription_id: sessionId,
      status: paymentStatus === "paid" ? "active" : "incomplete",
      plan: planKey,
      metadata: { mode },
    });
  }

  if (sessionId) {
    await upsertBilling({
      ring_id: ringId,
      payer_id: payerId,
      amount_cents: amount,
      currency,
      status: paymentStatus === "paid" ? "paid" : "open",
      plan: planKey,
      provider_checkout_session_id: sessionId,
      metadata: { mode, subscription_id: subscriptionId },
    });
  }
}

async function handleSubscription(subscription: Record<string, unknown>) {
  const metadata = metadataFrom(subscription);
  const ringId = metadata.ring_id;
  const payerId = metadata.payer_id;
  const planKey = metadata.plan;
  const subscriptionId = stringValue(subscription.id);
  if (!ringId || !payerId || !planKey || !subscriptionId) return;

  await upsertSubscription({
    ring_id: ringId,
    user_id: payerId,
    provider_subscription_id: subscriptionId,
    status: subscriptionStatus(stringValue(subscription.status)),
    current_period_start: isoFromSeconds(subscription.current_period_start),
    current_period_end: isoFromSeconds(subscription.current_period_end),
    plan: planKey,
    metadata: {
      cancel_at_period_end: subscription.cancel_at_period_end ?? false,
      canceled_at: subscription.canceled_at ?? null,
    },
  });
}

async function handleInvoice(
  invoice: Record<string, unknown>,
  billingStatus: "paid" | "failed",
) {
  const metadata = invoiceMetadata(invoice);
  const ringId = metadata.ring_id;
  const payerId = metadata.payer_id;
  const planKey = metadata.plan;
  if (!ringId || !payerId || !planKey) return;

  const invoiceId = stringValue(invoice.id);
  const subscriptionId = stringValue(invoice.subscription);
  const amount = numberValue(invoice.amount_paid) ??
    numberValue(invoice.amount_due) ??
    BILLING_PLANS[planKey]?.amountCents ?? 0;
  const currency = stringValue(invoice.currency) ?? "eur";
  const period = firstInvoicePeriod(invoice);

  if (subscriptionId) {
    await upsertSubscription({
      ring_id: ringId,
      user_id: payerId,
      provider_subscription_id: subscriptionId,
      status: billingStatus === "paid" ? "active" : "past_due",
      current_period_start: period.start,
      current_period_end: period.end,
      plan: planKey,
      metadata: { invoice_id: invoiceId },
    });
  }

  await upsertBilling({
    ring_id: ringId,
    payer_id: payerId,
    amount_cents: amount,
    currency,
    status: billingStatus,
    period_start: period.start,
    period_end: period.end,
    plan: planKey,
    provider_invoice_id: invoiceId,
    metadata: { subscription_id: subscriptionId },
  });
}

function metadataFrom(object: Record<string, unknown>): Record<string, string> {
  const metadata = object.metadata;
  if (!metadata || typeof metadata !== "object") return {};
  return Object.fromEntries(
    Object.entries(metadata as Record<string, unknown>)
      .filter((entry): entry is [string, string] => typeof entry[1] === "string"),
  );
}

function invoiceMetadata(invoice: Record<string, unknown>): Record<string, string> {
  const direct = metadataFrom(invoice);
  if (direct.ring_id && direct.payer_id && direct.plan) return direct;

  const subscriptionDetails = invoice.subscription_details as
    | Record<string, unknown>
    | undefined;
  const nested = subscriptionDetails?.metadata;
  if (!nested || typeof nested !== "object") return direct;

  return {
    ...direct,
    ...Object.fromEntries(
      Object.entries(nested as Record<string, unknown>)
        .filter((entry): entry is [string, string] => typeof entry[1] === "string"),
    ),
  };
}

function firstInvoicePeriod(invoice: Record<string, unknown>) {
  const lines = invoice.lines as Record<string, unknown> | undefined;
  const data = Array.isArray(lines?.data) ? lines?.data : [];
  const first = data[0] as Record<string, unknown> | undefined;
  const period = first?.period as Record<string, unknown> | undefined;
  return {
    start: isoFromSeconds(period?.start),
    end: isoFromSeconds(period?.end),
  };
}

function subscriptionStatus(status: string | null): string {
  switch (status) {
    case "trialing":
    case "active":
    case "past_due":
    case "canceled":
    case "incomplete":
      return status;
    default:
      return "incomplete";
  }
}
