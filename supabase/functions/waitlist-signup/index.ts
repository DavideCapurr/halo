import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type WaitlistPayload = {
  display_name?: string;
  email?: string;
  role?: string;
  circle_size?: number | string | null;
  referral_source?: string | null;
  founder_code?: string | null;
  source?: string | null;
  metadata?: Record<string, unknown> | null;
};

const allowedRoles = new Set([
  "freshman",
  "msc",
  "exchange",
  "club_host",
  "founder_circle",
]);

const corsHeaders = {
  "Access-Control-Allow-Origin": Deno.env.get("HALO_LANDING_ORIGIN") ?? "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ ok: false, error: "method not allowed" }, 405);
  }

  let payload: WaitlistPayload;
  try {
    payload = await req.json();
  } catch {
    return json({ ok: false, error: "invalid json" }, 400);
  }

  const normalized = normalize(payload);
  const validation = validate(normalized);
  if (validation) {
    return json({ ok: false, error: validation }, 422);
  }

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const { data: campus, error: campusError } = await supa
    .from("campuses")
    .select("id")
    .eq("slug", "bocconi")
    .maybeSingle();

  if (campusError) {
    return json({ ok: false, error: campusError.message }, 500);
  }

  const row = {
    campus_id: campus?.id ?? null,
    email: normalized.email,
    display_name: normalized.display_name,
    role: normalized.role,
    circle_size: normalized.circle_size,
    referral_source: normalized.referral_source,
    founder_code: normalized.founder_code,
    source: normalized.source,
    status: "new",
    metadata: {
      ...(normalized.metadata ?? {}),
      user_agent: req.headers.get("user-agent") ?? null,
    },
  };

  const { error } = await supa
    .from("waitlist_signups")
    .insert(row);

  if (error?.code === "23505") {
    const updateRow = {
      campus_id: row.campus_id,
      display_name: row.display_name,
      role: row.role,
      circle_size: row.circle_size,
      referral_source: row.referral_source,
      founder_code: row.founder_code,
      source: row.source,
      metadata: row.metadata,
    };

    const { error: updateError } = await supa
      .from("waitlist_signups")
      .update(updateRow)
      .eq("email", normalized.email);

    if (updateError) {
      return json({ ok: false, error: updateError.message }, 500);
    }
  } else if (error) {
    return json({ ok: false, error: error.message }, 500);
  }

  return json({ ok: true, email: normalized.email }, 200);
});

function normalize(payload: WaitlistPayload) {
  const circleSize = payload.circle_size === null || payload.circle_size === undefined
    ? null
    : Number(payload.circle_size);

  return {
    display_name: clean(payload.display_name, 80),
    email: clean(payload.email, 180).toLowerCase(),
    role: clean(payload.role, 40),
    circle_size: Number.isFinite(circleSize) ? circleSize : null,
    referral_source: clean(payload.referral_source, 120) || null,
    founder_code: clean(payload.founder_code, 80).toUpperCase() || null,
    source: clean(payload.source, 80) || "landing_bocconi_cold_start",
    metadata: payload.metadata && typeof payload.metadata === "object" ? payload.metadata : {},
  };
}

function validate(payload: ReturnType<typeof normalize>): string | null {
  if (!payload.display_name) return "missing display_name";
  if (!/^[^@\s]+@[^@\s]+$/.test(payload.email)) return "invalid email";
  if (!payload.email.endsWith("@studbocconi.it")) {
    return "use a @studbocconi.it email";
  }
  if (!allowedRoles.has(payload.role)) return "invalid role";
  if (
    payload.circle_size !== null &&
    (!Number.isInteger(payload.circle_size) ||
      payload.circle_size < 1 ||
      payload.circle_size > 20)
  ) {
    return "invalid circle_size";
  }
  return null;
}

function clean(value: unknown, max: number): string {
  return String(value ?? "")
    .trim()
    .slice(0, max);
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
