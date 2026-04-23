-- Halo MVP — seed per smoke test locale
-- 8 profili, vibes attive, follow tier mix, 4 post con min_tier vari.
-- Gli id sono fissi per essere riferibili nei test RLS.
--
-- NOTA: `auth.users` va popolato prima di `profiles` perché profiles.id
-- referenzia auth.users(id). In locale inseriamo direttamente righe fittizie
-- in auth.users (solo email provider); in prod questo non serve — gli users
-- arrivano da Sign in with Apple.

set local session_replication_role = replica;  -- disabilita trigger / RLS in seed

-- ---------- auth.users fittizi ----------
insert into auth.users (id, aud, role, email, raw_user_meta_data, created_at, updated_at, email_confirmed_at, instance_id)
values
  ('11111111-1111-1111-1111-111111111111','authenticated','authenticated','ava@halo.test',  '{}'::jsonb, now(), now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('22222222-2222-2222-2222-222222222222','authenticated','authenticated','ben@halo.test',  '{}'::jsonb, now(), now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('33333333-3333-3333-3333-333333333333','authenticated','authenticated','cleo@halo.test', '{}'::jsonb, now(), now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('44444444-4444-4444-4444-444444444444','authenticated','authenticated','dino@halo.test', '{}'::jsonb, now(), now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('55555555-5555-5555-5555-555555555555','authenticated','authenticated','eli@halo.test',  '{}'::jsonb, now(), now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('66666666-6666-6666-6666-666666666666','authenticated','authenticated','fra@halo.test',  '{}'::jsonb, now(), now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('77777777-7777-7777-7777-777777777777','authenticated','authenticated','gio@halo.test',  '{}'::jsonb, now(), now(), now(), '00000000-0000-0000-0000-000000000000'),
  ('88888888-8888-8888-8888-888888888888','authenticated','authenticated','hal@halo.test',  '{}'::jsonb, now(), now(), now(), '00000000-0000-0000-0000-000000000000')
on conflict (id) do nothing;

-- ---------- profiles ----------
insert into public.profiles (id, handle, display_name, bio, has_plus) values
  ('11111111-1111-1111-1111-111111111111','ava',  'Ava Moretti',   'studio design, ascolto lo-fi tutto il giorno', true),
  ('22222222-2222-2222-2222-222222222222','ben',  'Ben Colombo',   'dev, runner, pessimo a cucinare', false),
  ('33333333-3333-3333-3333-333333333333','cleo', 'Cleo Ferri',    'musica, film, gatto', false),
  ('44444444-4444-4444-4444-444444444444','dino', 'Dino Russo',    'architettura e basket', false),
  ('55555555-5555-5555-5555-555555555555','eli',  'Eli Santoro',   'fotografia analogica', true),
  ('66666666-6666-6666-6666-666666666666','fra',  'Fra Bianchi',   'co-founder, cerco feedback UX', false),
  ('77777777-7777-7777-7777-777777777777','gio',  'Gio Marino',    'filosofia + sci', false),
  ('88888888-8888-8888-8888-888888888888','hal',  'Hal Lombardi',  'musicista, vocal coach', false)
on conflict (id) do nothing;

-- ---------- vibes attive ----------
insert into public.vibes (user_id, mood, color_hex, note) values
  ('11111111-1111-1111-1111-111111111111','focused', '#7C5CFF','deep work pomeriggio'),
  ('22222222-2222-2222-2222-222222222222','warm',    '#FF8A5C','caffè col team'),
  ('33333333-3333-3333-3333-333333333333','chill',   '#5CE1E6','pioggia in sottofondo'),
  ('44444444-4444-4444-4444-444444444444','electric','#F5D142','gara stasera'),
  ('55555555-5555-5555-5555-555555555555','soft',    '#FFB3C1','nuvola rosa'),
  ('66666666-6666-6666-6666-666666666666','wild',    '#E84A5F','pitch in 2h'),
  ('77777777-7777-7777-7777-777777777777','blue',    '#4A6FE8','giornata pesa'),
  ('88888888-8888-8888-8888-888888888888','lost',    '#9B9B9B','cercando una melodia')
on conflict do nothing;

-- ---------- follows (prospettiva di Ava=1) ----------
-- Ava ha Inner: Ben, Cleo. Close: Dino, Eli. Orbit: Fra, Gio. Nebula: Hal.
insert into public.follows (follower_id, followee_id, tier) values
  ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222','inner'),
  ('11111111-1111-1111-1111-111111111111','33333333-3333-3333-3333-333333333333','inner'),
  ('11111111-1111-1111-1111-111111111111','44444444-4444-4444-4444-444444444444','close'),
  ('11111111-1111-1111-1111-111111111111','55555555-5555-5555-5555-555555555555','close'),
  ('11111111-1111-1111-1111-111111111111','66666666-6666-6666-6666-666666666666','orbit'),
  ('11111111-1111-1111-1111-111111111111','77777777-7777-7777-7777-777777777777','orbit'),
  ('11111111-1111-1111-1111-111111111111','88888888-8888-8888-8888-888888888888','nebula')
on conflict do nothing;

-- Follow reciproche con tier diversi (per testare asimmetria del modello)
insert into public.follows (follower_id, followee_id, tier) values
  ('22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111','inner'),
  ('33333333-3333-3333-3333-333333333333','11111111-1111-1111-1111-111111111111','close'),
  ('44444444-4444-4444-4444-444444444444','11111111-1111-1111-1111-111111111111','close'),
  ('55555555-5555-5555-5555-555555555555','11111111-1111-1111-1111-111111111111','inner'),
  ('66666666-6666-6666-6666-666666666666','11111111-1111-1111-1111-111111111111','nebula'),
  ('77777777-7777-7777-7777-777777777777','11111111-1111-1111-1111-111111111111','orbit'),
  ('88888888-8888-8888-8888-888888888888','11111111-1111-1111-1111-111111111111','nebula')
on conflict do nothing;

-- ---------- halo_posts ----------
-- Post di Ava con min_tier vari: serve per testare RLS dai diversi punti di vista.
insert into public.halo_posts (user_id, kind, caption, mood, min_tier) values
  ('11111111-1111-1111-1111-111111111111','text',  'giornata lunga ma buona', 'focused','nebula'),
  ('11111111-1111-1111-1111-111111111111','text',  'quello sketch mi tormenta','soft',  'orbit'),
  ('11111111-1111-1111-1111-111111111111','text',  'domanda vera: ne vale la pena?','blue','close'),
  ('11111111-1111-1111-1111-111111111111','audio', 'voice memo 18s',            'warm',  'inner');
