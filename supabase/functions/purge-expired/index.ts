// Halo — purge-expired
// Edge function schedulata via pg_cron ogni ora.
//
// I Moment scaduti restano in halo_posts per Halo+ Memory: RLS/RPC decidono chi
// può riaprirli. Questo job elimina solo le vibes scadute, che non hanno una
// superficie Memory privata.
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

  // I post scaduti vengono trattenuti per Memory.
  const { count: retainedPosts, error: selErr } = await supa
    .from("halo_posts")
    .select("id", { count: "exact", head: true })
    .lt("expires_at", new Date().toISOString());

  if (selErr) {
    return new Response(JSON.stringify({ ok: false, error: selErr.message }), {
      status: 500,
    });
  }

  // Vibes scadute: nessun media, basta cancellare le righe.
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
      postsRetainedForMemory: retainedPosts ?? 0,
      vibesDeleted: vibesDeleted ?? 0,
      mediaBucket: MEDIA_BUCKET,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
