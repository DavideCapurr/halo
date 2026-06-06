-- Halo product rings + Memory archive.
-- Rings cover Event / Club / Course / Founder with shared membership,
-- token joins, event check-ins and club/course billing hooks.

do $$ begin
  create type ring_type_enum as enum ('event', 'club', 'course', 'founder');
exception when duplicate_object then null; end $$;

create table if not exists public.rings (
  id                uuid primary key default gen_random_uuid(),
  kind              ring_type_enum not null,
  creator_id        uuid not null references public.profiles(id) on delete cascade,
  campus_id         uuid references public.campuses(id) on delete set null,
  title             text not null check (char_length(trim(title)) between 2 and 80),
  subtitle          text check (char_length(coalesce(subtitle, '')) <= 180),
  location_name     text check (char_length(coalesce(location_name, '')) <= 120),
  starts_at         timestamptz,
  ends_at           timestamptz,
  expires_at        timestamptz,
  join_token        text not null unique default encode(extensions.gen_random_bytes(16), 'hex'),
  is_public         boolean not null default false,
  requires_approval boolean not null default false,
  member_limit      integer check (member_limit is null or member_limit > 0),
  price_cents       integer check (price_cents is null or price_cents >= 0),
  currency          text not null default 'eur' check (currency ~ '^[a-z]{3}$'),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at >= starts_at),
  check (expires_at is null or starts_at is null or expires_at >= starts_at),
  check (kind in ('club', 'course') or price_cents is null or price_cents = 0)
);

create index if not exists rings_kind_starts_idx
  on public.rings (kind, starts_at desc nulls last, created_at desc);

create index if not exists rings_creator_created_idx
  on public.rings (creator_id, created_at desc);

create index if not exists rings_public_kind_idx
  on public.rings (kind, created_at desc)
  where is_public = true;

create table if not exists public.ring_members (
  ring_id    uuid not null references public.rings(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  role       text not null default 'member'
             check (role in ('owner', 'admin', 'host', 'founder', 'member')),
  status     text not null default 'active'
             check (status in ('active', 'pending', 'removed')),
  joined_at  timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (ring_id, user_id)
);

create index if not exists ring_members_user_status_idx
  on public.ring_members (user_id, status, joined_at desc);

create index if not exists ring_members_ring_status_idx
  on public.ring_members (ring_id, status, joined_at desc);

create table if not exists public.event_checkins (
  id            uuid primary key default gen_random_uuid(),
  ring_id       uuid not null references public.rings(id) on delete cascade,
  user_id       uuid not null references public.profiles(id) on delete cascade,
  source        text not null default 'qr' check (source in ('qr', 'manual')),
  checked_in_at timestamptz not null default now(),
  unique (ring_id, user_id)
);

create index if not exists event_checkins_ring_checked_idx
  on public.event_checkins (ring_id, checked_in_at desc);

create table if not exists public.subscriptions (
  id                       uuid primary key default gen_random_uuid(),
  ring_id                  uuid not null references public.rings(id) on delete cascade,
  user_id                  uuid not null references public.profiles(id) on delete cascade,
  provider                 text not null default 'manual'
                           check (provider in ('storekit', 'stripe', 'manual', 'comped')),
  provider_subscription_id text,
  status                   text not null default 'active'
                           check (status in ('trialing', 'active', 'past_due', 'canceled', 'incomplete', 'comped')),
  current_period_start     timestamptz,
  current_period_end       timestamptz,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),
  unique (provider, provider_subscription_id)
);

create index if not exists subscriptions_user_status_idx
  on public.subscriptions (user_id, status, created_at desc);

create index if not exists subscriptions_ring_status_idx
  on public.subscriptions (ring_id, status, created_at desc);

create table if not exists public.club_billing (
  id              uuid primary key default gen_random_uuid(),
  ring_id         uuid not null references public.rings(id) on delete cascade,
  subscription_id uuid references public.subscriptions(id) on delete set null,
  payer_id        uuid not null references public.profiles(id) on delete cascade,
  provider        text not null default 'stripe'
                  check (provider in ('stripe', 'storekit', 'manual', 'comped')),
  amount_cents    integer not null check (amount_cents >= 0),
  currency        text not null default 'eur' check (currency ~ '^[a-z]{3}$'),
  status          text not null default 'open'
                  check (status in ('draft', 'open', 'paid', 'void', 'failed')),
  period_start    timestamptz,
  period_end      timestamptz,
  created_at      timestamptz not null default now()
);

create index if not exists club_billing_payer_created_idx
  on public.club_billing (payer_id, created_at desc);

create index if not exists club_billing_ring_created_idx
  on public.club_billing (ring_id, created_at desc);

create or replace function public.rings_touch_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end
$$;

drop trigger if exists trg_rings_touch_updated_at on public.rings;
create trigger trg_rings_touch_updated_at
before update on public.rings
for each row execute function public.rings_touch_updated_at();

drop trigger if exists trg_subscriptions_touch_updated_at on public.subscriptions;
create trigger trg_subscriptions_touch_updated_at
before update on public.subscriptions
for each row execute function public.rings_touch_updated_at();

create or replace function public.is_ring_member(p_ring_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.ring_members rm
    where rm.ring_id = p_ring_id
      and rm.user_id = p_user_id
      and rm.status = 'active'
  )
$$;

create or replace function public.can_manage_ring(p_ring_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.ring_members rm
    where rm.ring_id = p_ring_id
      and rm.user_id = p_user_id
      and rm.status = 'active'
      and rm.role in ('owner', 'admin', 'host')
  )
$$;

create or replace function public.rings_add_owner_member()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.ring_members (ring_id, user_id, role, status)
  values (
    new.id,
    new.creator_id,
    case when new.kind = 'founder' then 'founder' else 'owner' end,
    'active'
  )
  on conflict (ring_id, user_id) do nothing;
  return new;
end
$$;

drop trigger if exists trg_rings_add_owner_member on public.rings;
create trigger trg_rings_add_owner_member
after insert on public.rings
for each row execute function public.rings_add_owner_member();

create or replace function public.join_ring_by_token(p_token text)
returns public.rings
language plpgsql
security definer
set search_path = public
as $$
declare
  target public.rings%rowtype;
  next_status text;
  active_members integer;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select *
    into target
  from public.rings r
  where r.join_token = trim(p_token)
    and (r.expires_at is null or r.expires_at > now())
  limit 1;

  if target.id is null then
    raise exception 'ring token not found';
  end if;

  select count(*)
    into active_members
  from public.ring_members rm
  where rm.ring_id = target.id
    and rm.status = 'active';

  if target.member_limit is not null
     and active_members >= target.member_limit
     and not public.is_ring_member(target.id, auth.uid()) then
    raise exception 'ring is full';
  end if;

  next_status := case when target.requires_approval then 'pending' else 'active' end;

  insert into public.ring_members (ring_id, user_id, role, status, joined_at)
  values (target.id, auth.uid(), 'member', next_status, now())
  on conflict (ring_id, user_id) do update
    set status = excluded.status,
        joined_at = case
          when ring_members.status = 'removed' then excluded.joined_at
          else ring_members.joined_at
        end;

  return target;
end
$$;

create or replace function public.join_public_ring(p_ring_id uuid)
returns public.rings
language plpgsql
security definer
set search_path = public
as $$
declare
  target public.rings%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select *
    into target
  from public.rings r
  where r.id = p_ring_id
    and r.is_public = true
    and (r.expires_at is null or r.expires_at > now())
  limit 1;

  if target.id is null then
    raise exception 'public ring not found';
  end if;

  return public.join_ring_by_token(target.join_token);
end
$$;

create or replace function public.refresh_ring_join_token(p_ring_id uuid)
returns public.rings
language plpgsql
security definer
set search_path = public
as $$
declare
  target public.rings%rowtype;
begin
  if not public.can_manage_ring(p_ring_id, auth.uid()) then
    raise exception 'not allowed';
  end if;

  update public.rings
  set join_token = encode(extensions.gen_random_bytes(16), 'hex')
  where id = p_ring_id
  returning * into target;

  return target;
end
$$;

create or replace function public.check_in_event_ring(p_ring_id uuid)
returns public.event_checkins
language plpgsql
security definer
set search_path = public
as $$
declare
  target public.rings%rowtype;
  saved public.event_checkins%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select *
    into target
  from public.rings r
  where r.id = p_ring_id
    and r.kind = 'event'
    and (r.expires_at is null or r.expires_at > now())
  limit 1;

  if target.id is null then
    raise exception 'event ring not found';
  end if;

  if not public.is_ring_member(target.id, auth.uid()) then
    raise exception 'join the ring before check-in';
  end if;

  insert into public.event_checkins (ring_id, user_id, source, checked_in_at)
  values (target.id, auth.uid(), 'qr', now())
  on conflict (ring_id, user_id) do update
    set checked_in_at = excluded.checked_in_at,
        source = excluded.source
  returning * into saved;

  return saved;
end
$$;

alter table public.rings          enable row level security;
alter table public.ring_members   enable row level security;
alter table public.event_checkins enable row level security;
alter table public.subscriptions  enable row level security;
alter table public.club_billing   enable row level security;

grant select, insert, update, delete on table public.rings to authenticated;
grant select, insert, update, delete on table public.ring_members to authenticated;
grant select, insert, update, delete on table public.event_checkins to authenticated;
grant select, insert, update on table public.subscriptions to authenticated;
grant select, insert, update on table public.club_billing to authenticated;

grant execute on function public.join_ring_by_token(text) to authenticated;
grant execute on function public.join_public_ring(uuid) to authenticated;
grant execute on function public.refresh_ring_join_token(uuid) to authenticated;
grant execute on function public.check_in_event_ring(uuid) to authenticated;

drop policy if exists rings_select_visible on public.rings;
create policy rings_select_visible on public.rings
  for select to authenticated
  using (
    is_public = true
    or creator_id = auth.uid()
    or public.is_ring_member(id, auth.uid())
  );

drop policy if exists rings_insert_creator on public.rings;
create policy rings_insert_creator on public.rings
  for insert to authenticated
  with check (creator_id = auth.uid());

drop policy if exists rings_update_manager on public.rings;
create policy rings_update_manager on public.rings
  for update to authenticated
  using (creator_id = auth.uid() or public.can_manage_ring(id, auth.uid()))
  with check (creator_id = auth.uid() or public.can_manage_ring(id, auth.uid()));

drop policy if exists rings_delete_creator on public.rings;
create policy rings_delete_creator on public.rings
  for delete to authenticated
  using (creator_id = auth.uid());

drop policy if exists ring_members_select_involved on public.ring_members;
create policy ring_members_select_involved on public.ring_members
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.can_manage_ring(ring_id, auth.uid())
  );

drop policy if exists ring_members_insert_public_self on public.ring_members;
create policy ring_members_insert_public_self on public.ring_members
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and role = 'member'
    and status in ('active', 'pending')
    and exists (
      select 1
      from public.rings r
      where r.id = ring_members.ring_id
        and r.is_public = true
        and (r.expires_at is null or r.expires_at > now())
    )
  );

drop policy if exists ring_members_update_manager on public.ring_members;
create policy ring_members_update_manager on public.ring_members
  for update to authenticated
  using (public.can_manage_ring(ring_id, auth.uid()))
  with check (public.can_manage_ring(ring_id, auth.uid()));

drop policy if exists ring_members_delete_manager on public.ring_members;
create policy ring_members_delete_manager on public.ring_members
  for delete to authenticated
  using (public.can_manage_ring(ring_id, auth.uid()));

drop policy if exists event_checkins_select_involved on public.event_checkins;
create policy event_checkins_select_involved on public.event_checkins
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.can_manage_ring(ring_id, auth.uid())
  );

drop policy if exists event_checkins_insert_self_member on public.event_checkins;
create policy event_checkins_insert_self_member on public.event_checkins
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and public.is_ring_member(ring_id, auth.uid())
    and exists (
      select 1
      from public.rings r
      where r.id = event_checkins.ring_id
        and r.kind = 'event'
    )
  );

drop policy if exists subscriptions_select_involved on public.subscriptions;
create policy subscriptions_select_involved on public.subscriptions
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.can_manage_ring(ring_id, auth.uid())
  );

drop policy if exists subscriptions_insert_self_member on public.subscriptions;
create policy subscriptions_insert_self_member on public.subscriptions
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and public.is_ring_member(ring_id, auth.uid())
  );

drop policy if exists subscriptions_update_self_or_manager on public.subscriptions;
create policy subscriptions_update_self_or_manager on public.subscriptions
  for update to authenticated
  using (
    user_id = auth.uid()
    or public.can_manage_ring(ring_id, auth.uid())
  )
  with check (
    user_id = auth.uid()
    or public.can_manage_ring(ring_id, auth.uid())
  );

drop policy if exists club_billing_select_involved on public.club_billing;
create policy club_billing_select_involved on public.club_billing
  for select to authenticated
  using (
    payer_id = auth.uid()
    or public.can_manage_ring(ring_id, auth.uid())
  );

drop policy if exists club_billing_insert_self_or_manager on public.club_billing;
create policy club_billing_insert_self_or_manager on public.club_billing
  for insert to authenticated
  with check (
    payer_id = auth.uid()
    or public.can_manage_ring(ring_id, auth.uid())
  );

drop policy if exists club_billing_update_manager on public.club_billing;
create policy club_billing_update_manager on public.club_billing
  for update to authenticated
  using (public.can_manage_ring(ring_id, auth.uid()))
  with check (public.can_manage_ring(ring_id, auth.uid()));

-- Memory archive: authors can reopen their expired posts. Everyone else still
-- sees only alive posts allowed by tier/public-profile rules.
drop policy if exists halo_posts_select_tiered on public.halo_posts;
create policy halo_posts_select_tiered on public.halo_posts
  for select to authenticated
  using (
    user_id = auth.uid()
    or (
      expires_at > now()
      and (
        public.tier_rank(public.viewer_tier_towards(user_id))
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
    )
  );
