-- Halo MVP — Row Level Security
-- Principio: il tier del viewer (auth.uid) verso l'autore del contenuto
-- determina cosa è visibile. nebula<orbit<close<inner.

-- ---------- enable RLS ----------
alter table public.profiles   enable row level security;
alter table public.vibes      enable row level security;
alter table public.halo_posts enable row level security;
alter table public.reactions  enable row level security;
alter table public.follows    enable row level security;

-- ---------- helper: tier del viewer verso un autore ----------
-- Se non segue, ritorna NULL (significa "invisibile per contenuti tier-gated").
create or replace function public.viewer_tier_towards(author_id uuid)
returns friendship_tier
language sql stable security definer set search_path = public as $$
  select f.tier
  from public.follows f
  where f.follower_id = auth.uid()
    and f.followee_id = author_id
  limit 1
$$;

-- ---------- profiles ----------
-- Tutti i profili autenticati sono visibili (necessari per ricerca handle / Nebula).
drop policy if exists profiles_select_authenticated on public.profiles;
create policy profiles_select_authenticated on public.profiles
  for select to authenticated
  using (true);

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
  for insert to authenticated
  with check (id = auth.uid());

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ---------- vibes ----------
-- Chiunque segua almeno a Nebula vede la vibe attiva.
drop policy if exists vibes_select_followers on public.vibes;
create policy vibes_select_followers on public.vibes
  for select to authenticated
  using (
    expires_at > now()
    and (
      user_id = auth.uid()
      or public.viewer_tier_towards(user_id) is not null
    )
  );

drop policy if exists vibes_insert_self on public.vibes;
create policy vibes_insert_self on public.vibes
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists vibes_update_self on public.vibes;
create policy vibes_update_self on public.vibes
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists vibes_delete_self on public.vibes;
create policy vibes_delete_self on public.vibes
  for delete to authenticated
  using (user_id = auth.uid());

-- ---------- halo_posts ----------
-- Visibile se non scaduto E (autore OR tier del viewer >= min_tier).
drop policy if exists halo_posts_select_tiered on public.halo_posts;
create policy halo_posts_select_tiered on public.halo_posts
  for select to authenticated
  using (
    expires_at > now()
    and (
      user_id = auth.uid()
      or public.tier_rank(public.viewer_tier_towards(user_id))
         >= public.tier_rank(min_tier)
    )
  );

drop policy if exists halo_posts_insert_self on public.halo_posts;
create policy halo_posts_insert_self on public.halo_posts
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists halo_posts_update_self on public.halo_posts;
create policy halo_posts_update_self on public.halo_posts
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists halo_posts_delete_self on public.halo_posts;
create policy halo_posts_delete_self on public.halo_posts
  for delete to authenticated
  using (user_id = auth.uid());

-- ---------- reactions ----------
-- SELECT: visibile se il viewer può vedere il post sottostante.
-- (la policy su halo_posts fa già il gating; qui replichiamo per coerenza.)
drop policy if exists reactions_select_if_post_visible on public.reactions;
create policy reactions_select_if_post_visible on public.reactions
  for select to authenticated
  using (
    exists (
      select 1 from public.halo_posts p
      where p.id = reactions.post_id
        and p.expires_at > now()
        and (
          p.user_id = auth.uid()
          or public.tier_rank(public.viewer_tier_towards(p.user_id))
             >= public.tier_rank(p.min_tier)
        )
    )
  );

-- INSERT: actor_id = auth.uid e il viewer può vedere il post.
drop policy if exists reactions_insert_self on public.reactions;
create policy reactions_insert_self on public.reactions
  for insert to authenticated
  with check (
    actor_id = auth.uid()
    and exists (
      select 1 from public.halo_posts p
      where p.id = reactions.post_id
        and p.expires_at > now()
        and (
          p.user_id = auth.uid()
          or public.tier_rank(public.viewer_tier_towards(p.user_id))
             >= public.tier_rank(p.min_tier)
        )
    )
  );

drop policy if exists reactions_delete_self on public.reactions;
create policy reactions_delete_self on public.reactions
  for delete to authenticated
  using (actor_id = auth.uid());

-- NOTA: la regola UX "Inner/Close vedono chi+cosa, Orbit vede solo aggregato"
-- è client-side: lato client, per min_tier='orbit' l'app mostra solo il COUNT
-- aggregato. Il DB permette la SELECT ma il client non espone l'actor_id.
-- In v1.1 valuteremo se spostare l'aggregazione su una view SECURITY DEFINER.

-- ---------- follows ----------
-- Ogni utente vede solo le follow che lo coinvolgono (come follower o followee).
drop policy if exists follows_select_involved on public.follows;
create policy follows_select_involved on public.follows
  for select to authenticated
  using (follower_id = auth.uid() or followee_id = auth.uid());

-- INSERT: solo come follower di te stesso. Il tier iniziale dev'essere nebula
-- (i tier superiori richiedono conferma via proposed_tier).
drop policy if exists follows_insert_as_follower on public.follows;
create policy follows_insert_as_follower on public.follows
  for insert to authenticated
  with check (
    follower_id = auth.uid()
    and tier = 'nebula'
  );

-- UPDATE: entrambe le parti possono aggiornare la riga (per proposte/conferme).
-- La logica fine "chi può promuovere a quale tier" è nei trigger 0003.
drop policy if exists follows_update_involved on public.follows;
create policy follows_update_involved on public.follows
  for update to authenticated
  using (follower_id = auth.uid() or followee_id = auth.uid())
  with check (follower_id = auth.uid() or followee_id = auth.uid());

drop policy if exists follows_delete_self on public.follows;
create policy follows_delete_self on public.follows
  for delete to authenticated
  using (follower_id = auth.uid());
