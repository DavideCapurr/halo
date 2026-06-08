-- Penny campaigns à la Mike Hayes.
-- A creator sets a goal and collects many small *real* donations that propagate
-- through the Halo graph (tier / Nebula) and via a public web link.
--
-- Money model: Halo NEVER holds donor funds. Donations flow donor -> creator via
-- Stripe Connect *direct charges* (creator is merchant of record); Halo only
-- records contribution state and takes a platform application fee. This migration
-- covers data + RLS + aggregate triggers + public read RPCs (no payment wiring,
-- that lands with the Stripe Edge Functions in a later phase).

create table if not exists public.campaigns (
  id                uuid primary key default gen_random_uuid(),
  creator_id        uuid not null references public.profiles(id) on delete cascade,
  title             text not null check (char_length(trim(title)) between 2 and 80),
  description       text check (char_length(coalesce(description, '')) <= 2000),
  cover_path        text,
  goal_cents        integer not null check (goal_cents > 0),
  currency          text not null default 'eur' check (currency ~ '^[a-z]{3}$'),
  -- Maintained by trigger from paid contributions. goal_cents is a milestone,
  -- NOT a cap: donations keep being accepted past 100% (overfunding).
  raised_cents      integer not null default 0 check (raised_cents >= 0),
  supporter_count   integer not null default 0 check (supporter_count >= 0),
  -- In-Halo propagation reuses the same tier gating as posts. Default 'nebula'
  -- = visible to everyone who follows the creator (incl. asymmetric/public).
  min_tier          friendship_tier not null default 'nebula',
  is_public         boolean not null default true,
  status            text not null default 'active'
                    check (status in ('draft', 'active', 'closed')),
  public_slug       text not null unique
                    default encode(extensions.gen_random_bytes(8), 'hex'),
  join_token        text not null unique
                    default encode(extensions.gen_random_bytes(16), 'hex'),
  -- Stripe connected account that receives the funds (creator merchant of record).
  stripe_account_id text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  expires_at        timestamptz
);

create index if not exists campaigns_creator_created_idx
  on public.campaigns (creator_id, created_at desc);

create index if not exists campaigns_public_created_idx
  on public.campaigns (created_at desc)
  where is_public = true and status <> 'draft';

create table if not exists public.campaign_contributions (
  id                    uuid primary key default gen_random_uuid(),
  campaign_id           uuid not null references public.campaigns(id) on delete cascade,
  -- Null for anonymous web donors (non-Halo users).
  contributor_id        uuid references public.profiles(id) on delete set null,
  display_name          text check (char_length(coalesce(display_name, '')) <= 80),
  message               text check (char_length(coalesce(message, '')) <= 280),
  amount_cents          integer not null check (amount_cents > 0),
  application_fee_cents  integer not null default 0 check (application_fee_cents >= 0),
  currency              text not null default 'eur' check (currency ~ '^[a-z]{3}$'),
  provider              text not null default 'stripe' check (provider in ('stripe')),
  provider_payment_id   text unique,
  -- Only 'paid' rows count toward campaign totals (see trigger below).
  status                text not null default 'pending'
                        check (status in ('pending', 'paid', 'failed', 'refunded')),
  is_anonymous          boolean not null default false,
  created_at            timestamptz not null default now()
);

create index if not exists campaign_contributions_campaign_created_idx
  on public.campaign_contributions (campaign_id, created_at desc);

create index if not exists campaign_contributions_contributor_idx
  on public.campaign_contributions (contributor_id, created_at desc);

create index if not exists campaign_contributions_campaign_paid_idx
  on public.campaign_contributions (campaign_id)
  where status = 'paid';

-- Reuse the generic updated_at toucher from the rings migration.
drop trigger if exists trg_campaigns_touch_updated_at on public.campaigns;
create trigger trg_campaigns_touch_updated_at
before update on public.campaigns
for each row execute function public.rings_touch_updated_at();

-- Recompute campaign totals from paid contributions on any contribution change.
create or replace function public.campaigns_recalc_totals()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_id uuid := coalesce(new.campaign_id, old.campaign_id);
begin
  update public.campaigns c
  set raised_cents    = coalesce(agg.total, 0),
      supporter_count = coalesce(agg.cnt, 0)
  from (
    select sum(amount_cents) as total, count(*) as cnt
    from public.campaign_contributions
    where campaign_id = target_id
      and status = 'paid'
  ) agg
  where c.id = target_id;
  return null;
end
$$;

drop trigger if exists trg_campaign_contributions_recalc on public.campaign_contributions;
create trigger trg_campaign_contributions_recalc
after insert or update or delete on public.campaign_contributions
for each row execute function public.campaigns_recalc_totals();

create or replace function public.is_campaign_contributor(p_campaign_id uuid, p_user_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1
    from public.campaign_contributions cc
    where cc.campaign_id = p_campaign_id
      and cc.contributor_id = p_user_id
  )
$$;

-- Public, anon-readable view of a single public campaign by slug (for the web
-- landing). Returns nothing for drafts / private / missing campaigns.
create or replace function public.public_campaign_by_slug(p_slug text)
returns table (
  id              uuid,
  title           text,
  description     text,
  cover_path      text,
  goal_cents      integer,
  currency        text,
  raised_cents    integer,
  supporter_count integer,
  status          text,
  created_at      timestamptz,
  expires_at      timestamptz
)
language sql stable security definer set search_path = public
as $$
  select c.id, c.title, c.description, c.cover_path, c.goal_cents, c.currency,
         c.raised_cents, c.supporter_count, c.status, c.created_at, c.expires_at
  from public.campaigns c
  where c.public_slug = trim(p_slug)
    and c.is_public = true
    and c.status <> 'draft'
  limit 1
$$;

-- Recent non-anonymous paid contributions for a public campaign (for the wall
-- of supporters on the web landing).
create or replace function public.public_campaign_supporters(p_slug text, p_limit integer default 50)
returns table (
  display_name text,
  message      text,
  amount_cents integer,
  created_at   timestamptz
)
language sql stable security definer set search_path = public
as $$
  select cc.display_name, cc.message, cc.amount_cents, cc.created_at
  from public.campaign_contributions cc
  join public.campaigns c on c.id = cc.campaign_id
  where c.public_slug = trim(p_slug)
    and c.is_public = true
    and c.status <> 'draft'
    and cc.status = 'paid'
    and cc.is_anonymous = false
  order by cc.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
$$;

alter table public.campaigns              enable row level security;
alter table public.campaign_contributions enable row level security;

grant select, insert, update, delete on table public.campaigns to authenticated;
grant select, insert on table public.campaign_contributions to authenticated;

grant execute on function public.public_campaign_by_slug(text) to anon, authenticated;
grant execute on function public.public_campaign_supporters(text, integer) to anon, authenticated;

-- ---------- campaigns RLS ----------
drop policy if exists campaigns_select_visible on public.campaigns;
create policy campaigns_select_visible on public.campaigns
  for select to authenticated
  using (
    creator_id = auth.uid()
    or (
      status <> 'draft'
      and (
        is_public = true
        or public.is_campaign_contributor(id, auth.uid())
        or public.tier_rank(public.viewer_tier_towards(creator_id))
           >= public.tier_rank(min_tier)
      )
    )
  );

drop policy if exists campaigns_insert_creator on public.campaigns;
create policy campaigns_insert_creator on public.campaigns
  for insert to authenticated
  with check (creator_id = auth.uid());

drop policy if exists campaigns_update_creator on public.campaigns;
create policy campaigns_update_creator on public.campaigns
  for update to authenticated
  using (creator_id = auth.uid())
  with check (creator_id = auth.uid());

drop policy if exists campaigns_delete_creator on public.campaigns;
create policy campaigns_delete_creator on public.campaigns
  for delete to authenticated
  using (creator_id = auth.uid());

-- ---------- campaign_contributions RLS ----------
-- The creator sees all contributions to their campaign; a contributor sees own.
drop policy if exists campaign_contributions_select_involved on public.campaign_contributions;
create policy campaign_contributions_select_involved on public.campaign_contributions
  for select to authenticated
  using (
    contributor_id = auth.uid()
    or exists (
      select 1 from public.campaigns c
      where c.id = campaign_contributions.campaign_id
        and c.creator_id = auth.uid()
    )
  );

-- Clients may only create their own *pending* intent. The real 'paid' state is
-- written by the Stripe webhook (service role, bypasses RLS) — clients can never
-- mark a contribution paid, so totals can't be forged.
drop policy if exists campaign_contributions_insert_self_pending on public.campaign_contributions;
create policy campaign_contributions_insert_self_pending on public.campaign_contributions
  for insert to authenticated
  with check (
    contributor_id = auth.uid()
    and status = 'pending'
    and application_fee_cents = 0
  );

-- ---------- campaign covers storage bucket ----------
-- Public bucket: covers must render on the open web landing without signed URLs.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'halo-campaigns',
  'halo-campaigns',
  true,
  5242880,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/heic', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists storage_campaigns_select_public on storage.objects;
create policy storage_campaigns_select_public on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'halo-campaigns');

drop policy if exists storage_campaigns_insert_own_folder on storage.objects;
create policy storage_campaigns_insert_own_folder on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'halo-campaigns'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists storage_campaigns_update_own_folder on storage.objects;
create policy storage_campaigns_update_own_folder on storage.objects
  for update to authenticated
  using (
    bucket_id = 'halo-campaigns'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'halo-campaigns'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists storage_campaigns_delete_own_folder on storage.objects;
create policy storage_campaigns_delete_own_folder on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'halo-campaigns'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
