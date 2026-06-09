import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export type BillingPlan = {
  key: string;
  priceEnv: string;
  mode: "payment" | "subscription";
  amountCents: number | null;
  interval: "month" | null;
};

export const BILLING_PLANS: Record<string, BillingPlan> = {
  event_guest: {
    key: "event_guest",
    priceEnv: "STRIPE_PRICE_EVENT_GUEST",
    mode: "payment",
    amountCents: 499,
    interval: null,
  },
  event_pro: {
    key: "event_pro",
    priceEnv: "STRIPE_PRICE_EVENT_PRO",
    mode: "payment",
    amountCents: 2900,
    interval: null,
  },
  event_beta: {
    key: "event_beta",
    priceEnv: "STRIPE_PRICE_EVENT_BETA",
    mode: "payment",
    amountCents: 7900,
    interval: null,
  },
  event_post_beta: {
    key: "event_post_beta",
    priceEnv: "STRIPE_PRICE_EVENT_POST_BETA",
    mode: "payment",
    amountCents: null,
    interval: null,
  },
  club_starter: {
    key: "club_starter",
    priceEnv: "STRIPE_PRICE_CLUB_STARTER",
    mode: "subscription",
    amountCents: 4900,
    interval: "month",
  },
  club_pro: {
    key: "club_pro",
    priceEnv: "STRIPE_PRICE_CLUB_PRO",
    mode: "subscription",
    amountCents: 9900,
    interval: "month",
  },
  club_scale: {
    key: "club_scale",
    priceEnv: "STRIPE_PRICE_CLUB_SCALE",
    mode: "subscription",
    amountCents: 14900,
    interval: "month",
  },
};

export function serviceClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

export function jsonResponse(body: unknown, init: ResponseInit = {}) {
  return new Response(JSON.stringify(body), {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
  });
}

export async function authenticatedUser(req: Request) {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) throw new Error("missing authorization");

  const { data, error } = await serviceClient().auth.getUser(token);
  if (error || !data.user) throw new Error("invalid authorization");
  return data.user;
}

export async function canManageRing(ringId: string, userId: string): Promise<boolean> {
  const { data, error } = await serviceClient()
    .rpc("can_manage_ring", { p_ring_id: ringId, p_user_id: userId });
  if (error) throw new Error(error.message);
  return Boolean(data);
}

export async function stripeRequest<T>(
  path: string,
  params: URLSearchParams,
): Promise<T> {
  const secret = Deno.env.get("STRIPE_SECRET_KEY");
  if (!secret) throw new Error("missing STRIPE_SECRET_KEY");

  const response = await fetch(`https://api.stripe.com/v1/${path}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${secret}`,
      "Content-Type": "application/x-www-form-urlencoded",
      "Stripe-Version": "2026-02-25.clover",
    },
    body: params,
  });

  const body = await response.json();
  if (!response.ok) {
    throw new Error(body?.error?.message ?? `stripe ${response.status}`);
  }
  return body as T;
}

export async function verifyStripeSignature(
  rawBody: string,
  signatureHeader: string | null,
): Promise<void> {
  const secret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  if (!secret) throw new Error("missing STRIPE_WEBHOOK_SECRET");
  if (!signatureHeader) throw new Error("missing stripe signature");

  const parts = Object.fromEntries(
    signatureHeader.split(",").map((part) => {
      const [key, value] = part.split("=", 2);
      return [key, value];
    }),
  );
  const timestamp = parts.t;
  const signatures = signatureHeader
    .split(",")
    .filter((part) => part.startsWith("v1="))
    .map((part) => part.slice(3));

  if (!timestamp || signatures.length === 0) {
    throw new Error("invalid stripe signature");
  }

  const age = Math.abs(Date.now() / 1000 - Number(timestamp));
  if (Number.isFinite(age) && age > 300) {
    throw new Error("stale stripe signature");
  }

  const expected = await hmacHex(secret, `${timestamp}.${rawBody}`);
  if (!signatures.some((sig) => timingSafeEqual(sig, expected))) {
    throw new Error("stripe signature mismatch");
  }
}

export async function upsertSubscription(row: {
  ring_id: string;
  user_id: string;
  provider_subscription_id: string;
  status: string;
  current_period_start?: string | null;
  current_period_end?: string | null;
  plan?: string | null;
  metadata?: Record<string, unknown>;
}) {
  const supa = serviceClient();
  const payload = {
    ...row,
    provider: "stripe",
    metadata: row.metadata ?? {},
  };

  const { error } = await supa
    .from("subscriptions")
    .upsert(payload, { onConflict: "provider,provider_subscription_id" });
  if (error) throw new Error(error.message);
}

export async function upsertBilling(row: {
  ring_id: string;
  payer_id: string;
  amount_cents: number;
  currency: string;
  status: string;
  period_start?: string | null;
  period_end?: string | null;
  plan?: string | null;
  provider_invoice_id?: string | null;
  provider_checkout_session_id?: string | null;
  metadata?: Record<string, unknown>;
}) {
  const supa = serviceClient();
  const payload = {
    ...row,
    provider: "stripe",
    metadata: row.metadata ?? {},
  };

  let existingId: string | null = null;
  if (row.provider_invoice_id) {
    const { data, error } = await supa
      .from("club_billing")
      .select("id")
      .eq("provider", "stripe")
      .eq("provider_invoice_id", row.provider_invoice_id)
      .maybeSingle();
    if (error) throw new Error(error.message);
    existingId = data?.id ?? null;
  } else if (row.provider_checkout_session_id) {
    const { data, error } = await supa
      .from("club_billing")
      .select("id")
      .eq("provider", "stripe")
      .eq("provider_checkout_session_id", row.provider_checkout_session_id)
      .maybeSingle();
    if (error) throw new Error(error.message);
    existingId = data?.id ?? null;
  }

  const query = existingId
    ? supa.from("club_billing").update(payload).eq("id", existingId)
    : supa.from("club_billing").insert(payload);
  const { error } = await query;
  if (error) throw new Error(error.message);
}

export function stringValue(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

export function numberValue(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

export function isoFromSeconds(value: unknown): string | null {
  const seconds = numberValue(value);
  return seconds ? new Date(seconds * 1000).toISOString() : null;
}

async function hmacHex(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(payload),
  );
  return [...new Uint8Array(signature)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function timingSafeEqual(lhs: string, rhs: string): boolean {
  if (lhs.length !== rhs.length) return false;
  let mismatch = 0;
  for (let index = 0; index < lhs.length; index += 1) {
    mismatch |= lhs.charCodeAt(index) ^ rhs.charCodeAt(index);
  }
  return mismatch === 0;
}
