-- Halo — profili pubblici (celeb / brand / artist).
-- 1. Aggiunge `is_public` su `profiles` (default false).
-- 2. RLS: post di profili pubblici con `min_tier = nebula` sono visibili a chiunque
--    sia loggato (chiunque "segue almeno a Nebula", più gli utenti senza follow se l'autore è pubblico).
-- 3. Vibes di profili pubblici visibili a chiunque sia autenticato.
-- 4. Indice di filtro per discovery (`is_public = true`).

alter table public.profiles
  add column if not exists is_public boolean not null default false;

create index if not exists profiles_is_public_idx
  on public.profiles (is_public)
  where is_public = true;

-- Nuova policy halo_posts: estende quella esistente con il caso "autore pubblico + min_tier nebula".
drop policy if exists halo_posts_select_tiered on public.halo_posts;
create policy halo_posts_select_tiered on public.halo_posts
  for select to authenticated
  using (
    expires_at > now()
    and (
      user_id = auth.uid()
      or public.tier_rank(public.viewer_tier_towards(user_id))
         >= public.tier_rank(min_tier)
      or (
        min_tier = 'nebula'
        and exists (
          select 1 from public.profiles p
          where p.id = halo_posts.user_id
            and p.is_public = true
        )
      )
    )
  );

-- Vibes: chiunque autenticato vede la vibe se l'autore è pubblico.
drop policy if exists vibes_select_followers on public.vibes;
create policy vibes_select_followers on public.vibes
  for select to authenticated
  using (
    expires_at > now()
    and (
      user_id = auth.uid()
      or public.viewer_tier_towards(user_id) is not null
      or exists (
        select 1 from public.profiles p
        where p.id = vibes.user_id
          and p.is_public = true
      )
    )
  );
