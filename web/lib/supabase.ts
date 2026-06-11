// Tiny anon-key client for the public campaign endpoints. No supabase-js needed:
// we just hit the PostgREST RPCs and the Edge Function with the public key. RLS
// + the SECURITY DEFINER public RPCs make sure only public campaigns are exposed.

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const ANON = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

export const ANON_KEY = ANON;
export const FUNCTIONS_URL = `${SUPABASE_URL}/functions/v1`;

export interface PublicCampaign {
  id: string;
  title: string;
  description: string | null;
  cover_path: string | null;
  goal_cents: number;
  currency: string;
  raised_cents: number;
  supporter_count: number;
  status: string;
  created_at: string;
  expires_at: string | null;
}

export interface PublicSupporter {
  display_name: string | null;
  message: string | null;
  amount_cents: number;
  created_at: string;
}

async function rpc<T>(fn: string, params: Record<string, unknown>): Promise<T> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: ANON,
      Authorization: `Bearer ${ANON}`,
    },
    body: JSON.stringify(params),
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`rpc ${fn} failed: ${res.status}`);
  return res.json() as Promise<T>;
}

export async function getCampaign(slug: string): Promise<PublicCampaign | null> {
  const rows = await rpc<PublicCampaign[]>("public_campaign_by_slug", { p_slug: slug });
  return rows[0] ?? null;
}

export async function getSupporters(slug: string): Promise<PublicSupporter[]> {
  return rpc<PublicSupporter[]>("public_campaign_supporters", { p_slug: slug, p_limit: 50 });
}

export function coverURL(path: string | null): string | null {
  if (!path) return null;
  return `${SUPABASE_URL}/storage/v1/object/public/halo-campaigns/${path}`;
}
