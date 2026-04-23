// Halo — purge-expired
// Edge function schedulata via pg_cron ogni ora. Cancella media scaduti su Storage
// e le righe corrispondenti in halo_posts / vibes se sono oltre expires_at.
//
// Trigger pg_cron esempio (da eseguire una volta in SQL):
//   select cron.schedule('halo_purge_expired','0 * * * *',
//     $$ select net.http_post(
//          url := 'http://kong:8000/functions/v1/purge-expired',
//          headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.service_role_key'))
//       ) $$);

import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const MEDIA_BUCKET = Deno.env.get("HALO_MEDIA_BUCKET") ?? "halo-media";

serve(async () => {
  const supa = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false },
  });

  // 1. Raccogli media_path dei post scaduti, poi delete su Storage + rows.
  const { data: expiredPosts, error: selErr } = await supa
    .from("halo_posts")
    .select("id, media_path")
    .lt("expires_at", new Date().toISOString());

  if (selErr) {
    return new Response(JSON.stringify({ ok: false, error: selErr.message }), {
      status: 500,
    });
  }

  const mediaPaths = (expiredPosts ?? [])
    .map((p) => p.media_path)
    .filter((p): p is string => !!p);

  if (mediaPaths.length > 0) {
    const { error: rmErr } = await supa.storage
      .from(MEDIA_BUCKET)
      .remove(mediaPaths);
    if (rmErr) {
      return new Response(
        JSON.stringify({ ok: false, stage: "storage", error: rmErr.message }),
        { status: 500 },
      );
    }
  }

  const { error: delPostsErr, count: postsDeleted } = await supa
    .from("halo_posts")
    .delete({ count: "exact" })
    .lt("expires_at", new Date().toISOString());

  if (delPostsErr) {
    return new Response(
      JSON.stringify({ ok: false, stage: "posts", error: delPostsErr.message }),
      { status: 500 },
    );
  }

  // 2. Vibes scadute: nessun media, basta cancellare le righe.
  const { error: delVibesErr, count: vibesDeleted } = await supa
    .from("vibes")
    .delete({ count: "exact" })
    .lt("expires_at", new Date().toISOString());

  if (delVibesErr) {
    return new Response(
      JSON.stringify({ ok: false, stage: "vibes", error: delVibesErr.message }),
      { status: 500 },
    );
  }

  return new Response(
    JSON.stringify({
      ok: true,
      postsDeleted: postsDeleted ?? 0,
      vibesDeleted: vibesDeleted ?? 0,
      mediaRemoved: mediaPaths.length,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
