-- Halo+ entitlement authority, Memory RPC/RLS, and B2B billing hardening.
--
-- StoreKit remains consumer-only through plus_entitlements. Stripe remains
-- organizer/admin billing for rings and never unlocks consumer Halo+ perks.

-- ---------- Halo+ entitlement authority ----------
create table if not exists public.plus_entitlements (
  user_id                 uuid not null references public.profiles(id) on delete cascade,
  provider                text not null default 'storekit'
                          check (provider in ('storekit', 'manual', 'comped')),
  product_id              text not null,
  original_transaction_id text not null,
  transaction_id          text,
  status                  text not null
                          check (status in (
                            'trialing',
                            'active',
                            'grace_period',
                            'billing_retry',
                            'expired',
                            'canceled',
                            'revoked',
                            'refunded'
                          )),
  current_period_start    timestamptz,
  current_period_end      timestamptz,
  environment             text not null default 'unknown'
                          check (environment in ('production', 'sandbox', 'xcode', 'local', 'unknown')),
  raw_payload             jsonb not null default '{}'::jsonb,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  primary key (provider, original_transaction_id)
);

create index if not exists plus_entitlements_user_status_idx
  on public.plus_entitlements (user_id, status, current_period_end desc nulls last);

create index if not exists plus_entitlements_original_transaction_idx
  on public.plus_entitlements (original_transaction_id);

alter table public.plus_entitlements enable row level security;

grant select on table public.plus_entitlements to authenticated;

drop policy if exists plus_entitlements_select_self on public.plus_entitlements;
create policy plus_entitlements_select_self on public.plus_entitlements
  for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function public.has_active_plus(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.plus_entitlements pe
    where pe.user_id = p_user_id
      and pe.product_id = 'app.halo.plus.monthly'
      and pe.status in ('trialing', 'active', 'grace_period', 'billing_retry')
      and (
        pe.provider in ('manual', 'comped')
        or pe.current_period_end is null
        or pe.current_period_end > now()
      )
  )
$$;

grant execute on function public.has_active_plus(uuid) to authenticated;

create or replace function public.sync_profile_has_plus(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles p
  set has_plus = public.has_active_plus(p_user_id)
  where p.id = p_user_id;
end
$$;

create or replace function public.profile_cached_has_plus(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select p.has_plus
    from public.profiles p
    where p.id = p_user_id
    limit 1
  ), false)
$$;

grant execute on function public.profile_cached_has_plus(uuid) to authenticated;

create or replace function public.plus_entitlements_touch()
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

create or replace function public.plus_entitlements_sync_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
begin
  if tg_op = 'DELETE' then
    target_user_id := old.user_id;
  else
    target_user_id := new.user_id;
  end if;

  perform public.sync_profile_has_plus(target_user_id);
  return coalesce(new, old);
end
$$;

drop trigger if exists trg_plus_entitlements_touch on public.plus_entitlements;
create trigger trg_plus_entitlements_touch
before insert or update on public.plus_entitlements
for each row execute function public.plus_entitlements_touch();

drop trigger if exists trg_plus_entitlements_sync_profile on public.plus_entitlements;
create trigger trg_plus_entitlements_sync_profile
after insert or update or delete on public.plus_entitlements
for each row execute function public.plus_entitlements_sync_profile();

-- Backfill the profile cache for any imported/manual entitlements.
update public.profiles p
set has_plus = public.has_active_plus(p.id);

-- Client profile writes must not be able to mint Halo+.
drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
  for insert to authenticated
  with check (
    id = (select auth.uid())
    and has_plus = false
  );

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (
    id = (select auth.uid())
    and has_plus = public.profile_cached_has_plus((select auth.uid()))
  );

-- ---------- Memory RPC + RLS ----------
create or replace function public.memory_count()
returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  total integer;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select count(*)::integer
    into total
  from public.halo_posts hp
  where hp.user_id = auth.uid()
    and hp.expires_at <= now();

  return coalesce(total, 0);
end
$$;

create or replace function public.memory_archive(p_limit integer default 80)
returns setof public.halo_posts
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  safe_limit integer;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not public.has_active_plus(auth.uid()) then
    raise exception 'halo_plus_required';
  end if;

  safe_limit := greatest(1, least(coalesce(p_limit, 80), 200));

  return query
    select hp.*
    from public.halo_posts hp
    where hp.user_id = auth.uid()
      and hp.expires_at <= now()
    order by hp.created_at desc
    limit safe_limit;
end
$$;

grant execute on function public.memory_count() to authenticated;
grant execute on function public.memory_archive(integer) to authenticated;

-- Authors see expired posts only with active Halo+. Other viewers only see
-- live posts that pass tier/public-profile visibility.
drop policy if exists halo_posts_select_tiered on public.halo_posts;
create policy halo_posts_select_tiered on public.halo_posts
  for select to authenticated
  using (
    (
      user_id = (select auth.uid())
      and (
        expires_at > now()
        or public.has_active_plus((select auth.uid()))
      )
    )
    or (
      expires_at > now()
      and user_id <> (select auth.uid())
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

-- ---------- Stripe B2B billing hardening ----------
-- StoreKit does not belong in organizer billing tables; Halo+ lives in
-- plus_entitlements.
alter table public.subscriptions
  drop constraint if exists subscriptions_provider_check;

alter table public.subscriptions
  add constraint subscriptions_provider_check
  check (provider in ('stripe', 'manual', 'comped'));

alter table public.club_billing
  drop constraint if exists club_billing_provider_check;

alter table public.club_billing
  add constraint club_billing_provider_check
  check (provider in ('stripe', 'manual', 'comped'));

alter table public.subscriptions
  add column if not exists plan text,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

alter table public.club_billing
  add column if not exists plan text,
  add column if not exists provider_invoice_id text,
  add column if not exists provider_checkout_session_id text,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

create unique index if not exists club_billing_provider_invoice_uidx
  on public.club_billing (provider, provider_invoice_id)
  where provider_invoice_id is not null;

create unique index if not exists club_billing_provider_checkout_session_uidx
  on public.club_billing (provider, provider_checkout_session_id)
  where provider_checkout_session_id is not null;

grant execute on function public.can_manage_ring(uuid, uuid) to authenticated;

revoke insert, update on table public.subscriptions from authenticated;
revoke insert, update on table public.club_billing from authenticated;

drop policy if exists subscriptions_insert_self_member on public.subscriptions;
drop policy if exists subscriptions_update_self_or_manager on public.subscriptions;
drop policy if exists club_billing_insert_self_or_manager on public.club_billing;
drop policy if exists club_billing_update_manager on public.club_billing;
