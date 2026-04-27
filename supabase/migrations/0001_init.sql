-- Halo MVP — schema iniziale
-- Enum, tabelle, indici. RLS e trigger sono nelle migration successive.

create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- ---------- enum ----------
do $$ begin
  create type mood_enum as enum ('chill','wild','lost','focused','warm','electric','blue','soft');
exception when duplicate_object then null; end $$;

do $$ begin
  create type post_kind_enum as enum ('photo','text','audio');
exception when duplicate_object then null; end $$;

do $$ begin
  create type reaction_enum as enum ('pulse','glow','echo','spark','drift','hush');
exception when duplicate_object then null; end $$;

do $$ begin
  create type friendship_tier as enum ('nebula','orbit','close','inner');
exception when duplicate_object then null; end $$;

-- Utility: ordine dei tier (nebula=1 ... inner=4).
-- Usata da RLS per confrontare il tier del viewer vs min_tier del post.
create or replace function public.tier_rank(t friendship_tier)
returns int language sql immutable as $$
  select case t
    when 'nebula' then 1
    when 'orbit'  then 2
    when 'close'  then 3
    when 'inner'  then 4
  end
$$;

-- ---------- profiles ----------
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  handle        citext unique not null,
  display_name  text not null,
  avatar_path   text,
  bio           text,
  has_plus      boolean not null default false,
  created_at    timestamptz not null default now()
);

create index if not exists profiles_handle_idx on public.profiles (handle);

-- ---------- vibes ----------
-- Una vibe attiva per utente (expires_at > now()).
-- In v1 la sostituzione della vibe attiva viene gestita dal client cancellando
-- prima le vibes ancora vive dell'utente corrente. Evitiamo un partial unique
-- index con `now()` perche Postgres richiede predicati IMMUTABLE.
create table if not exists public.vibes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  mood        mood_enum not null,
  color_hex   text not null check (color_hex ~ '^#[0-9A-Fa-f]{6}$'),
  note        text check (char_length(coalesce(note,'')) <= 140),
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null default (now() + interval '24 hours')
);

create index if not exists vibes_user_expires_idx
  on public.vibes (user_id, expires_at desc);

-- ---------- halo_posts ----------
create table if not exists public.halo_posts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  kind        post_kind_enum not null,
  media_path  text,
  caption     text check (char_length(coalesce(caption,'')) <= 280),
  mood        mood_enum,
  min_tier    friendship_tier not null default 'orbit',
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null default (now() + interval '72 hours')
);

create index if not exists halo_posts_user_expires_idx
  on public.halo_posts (user_id, expires_at desc);

create index if not exists halo_posts_alive_idx
  on public.halo_posts (expires_at desc);

-- ---------- reactions ----------
create table if not exists public.reactions (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.halo_posts(id) on delete cascade,
  actor_id   uuid not null references public.profiles(id) on delete cascade,
  kind       reaction_enum not null,
  created_at timestamptz not null default now(),
  unique (post_id, actor_id, kind)
);

create index if not exists reactions_post_idx on public.reactions (post_id);

-- ---------- follows ----------
-- follower_id "segue" followee_id con un certo tier.
-- proposed_tier/proposed_by per il flusso drag-to-tier in attesa di conferma.
create table if not exists public.follows (
  follower_id    uuid not null references public.profiles(id) on delete cascade,
  followee_id    uuid not null references public.profiles(id) on delete cascade,
  tier           friendship_tier not null default 'nebula',
  proposed_tier  friendship_tier,
  proposed_by    uuid references public.profiles(id) on delete set null,
  created_at     timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);

create index if not exists follows_followee_idx on public.follows (followee_id);
create index if not exists follows_follower_tier_idx on public.follows (follower_id, tier);
