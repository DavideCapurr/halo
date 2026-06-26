-- Launch measurement: authenticated product events and activation funnel.

do $$ begin
  create type analytics_event_name as enum (
    'signup',
    'invite_sent',
    'invite_accepted',
    'vibe_set',
    'moment_created',
    'ring_joined',
    'move_closer'
  );
exception when duplicate_object then null; end $$;

create table if not exists public.analytics_events (
  id             uuid primary key default gen_random_uuid(),
  event_name     analytics_event_name not null,
  user_id        uuid not null references public.profiles(id) on delete cascade,
  target_user_id uuid references public.profiles(id) on delete set null,
  post_id        uuid references public.halo_posts(id) on delete set null,
  ring_id        uuid references public.rings(id) on delete set null,
  invite_id      uuid references public.invites(id) on delete set null,
  tier           friendship_tier,
  metadata       jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now(),
  check (jsonb_typeof(metadata) = 'object')
);

create index if not exists analytics_events_name_created_idx
  on public.analytics_events (event_name, created_at desc);

create index if not exists analytics_events_user_created_idx
  on public.analytics_events (user_id, created_at desc);

create index if not exists analytics_events_activation_idx
  on public.analytics_events (user_id, event_name)
  where event_name in ('vibe_set', 'moment_created', 'ring_joined');

alter table public.analytics_events enable row level security;

revoke all on table public.analytics_events from anon, authenticated;
grant insert on table public.analytics_events to authenticated;
grant select, insert, update, delete on table public.analytics_events to service_role;

drop policy if exists analytics_events_insert_own on public.analytics_events;
create policy analytics_events_insert_own on public.analytics_events
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create or replace view public.activation_funnel as
with bocconi as (
  select id
  from public.campuses
  where slug = 'bocconi'
  limit 1
),
verified as (
  select distinct cv.user_id
  from public.campus_verifications cv
  join bocconi b on b.id = cv.campus_id
),
activated as (
  select distinct e.user_id
  from public.analytics_events e
  join verified v on v.user_id = e.user_id
  where e.event_name in ('vibe_set', 'moment_created', 'ring_joined')
)
select
  now() as measured_at,
  count(v.user_id)::integer as verified_users,
  count(a.user_id)::integer as activated_users,
  case
    when count(v.user_id) = 0 then 0::numeric
    else round(count(a.user_id)::numeric / count(v.user_id)::numeric, 4)
  end as verified_to_activated_rate,
  0.5000::numeric as target_rate,
  case
    when count(v.user_id) = 0 then false
    else (count(a.user_id)::numeric / count(v.user_id)::numeric) >= 0.5000
  end as target_met
from verified v
left join activated a on a.user_id = v.user_id;

revoke all on public.activation_funnel from anon, authenticated;
grant select on public.activation_funnel to service_role;

comment on view public.activation_funnel is
  'Bocconi launch funnel: verified campus users who reached activation via vibe, moment, or ring join. Target is 50%.';
