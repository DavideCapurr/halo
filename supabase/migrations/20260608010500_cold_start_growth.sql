-- Cold-start growth: Bocconi waitlist and Founder Circle recruiting pipeline.

do $$ begin
  create type waitlist_status_enum as enum (
    'new',
    'contacted',
    'invited',
    'verified',
    'rejected'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type founder_circle_status_enum as enum (
    'target',
    'pitched',
    'committed',
    'scanned',
    'activated',
    'dropped'
  );
exception when duplicate_object then null; end $$;

create table if not exists public.waitlist_signups (
  id            uuid primary key default gen_random_uuid(),
  campus_id     uuid references public.campuses(id) on delete set null,
  email         citext not null unique,
  display_name  text not null check (char_length(trim(display_name)) between 1 and 80),
  role          text not null check (
    role in ('freshman', 'msc', 'exchange', 'club_host', 'founder_circle')
  ),
  circle_size   integer check (circle_size is null or circle_size between 1 and 20),
  referral_source text check (char_length(coalesce(referral_source, '')) <= 120),
  founder_code  citext,
  source        text not null default 'landing_bocconi_cold_start',
  status        waitlist_status_enum not null default 'new',
  notes         text check (char_length(coalesce(notes, '')) <= 1000),
  metadata      jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  check (email ~* '^[^@[:space:]]+@[^@[:space:]]+$')
);

create index if not exists waitlist_signups_status_created_idx
  on public.waitlist_signups (status, created_at desc);

create index if not exists waitlist_signups_campus_created_idx
  on public.waitlist_signups (campus_id, created_at desc);

create table if not exists public.founder_circle_recruits (
  id              uuid primary key default gen_random_uuid(),
  campus_id       uuid references public.campuses(id) on delete set null,
  slot            integer check (slot is null or slot between 1 and 200),
  segment         text not null check (char_length(trim(segment)) between 2 and 80),
  circle_name     text not null check (char_length(trim(circle_name)) between 2 and 120),
  lead_name       text check (char_length(coalesce(lead_name, '')) <= 80),
  lead_email      citext check (
    lead_email is null or lead_email ~* '^[^@[:space:]]+@[^@[:space:]]+$'
  ),
  target_size     integer not null default 5 check (target_size between 2 and 20),
  status          founder_circle_status_enum not null default 'target',
  next_step       text check (char_length(coalesce(next_step, '')) <= 180),
  orientation_token text not null default 'bocconi-orientation-week',
  notes           text check (char_length(coalesce(notes, '')) <= 1000),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create unique index if not exists founder_circle_recruits_campus_slot_idx
  on public.founder_circle_recruits (campus_id, slot)
  where slot is not null;

create index if not exists founder_circle_recruits_status_idx
  on public.founder_circle_recruits (status, created_at desc);

create or replace function public.cold_start_touch_updated_at()
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

drop trigger if exists trg_waitlist_signups_touch_updated_at on public.waitlist_signups;
create trigger trg_waitlist_signups_touch_updated_at
before update on public.waitlist_signups
for each row execute function public.cold_start_touch_updated_at();

drop trigger if exists trg_founder_circle_recruits_touch_updated_at on public.founder_circle_recruits;
create trigger trg_founder_circle_recruits_touch_updated_at
before update on public.founder_circle_recruits
for each row execute function public.cold_start_touch_updated_at();

alter table public.waitlist_signups enable row level security;
alter table public.founder_circle_recruits enable row level security;

grant insert on table public.waitlist_signups to anon, authenticated;

drop policy if exists waitlist_signups_insert_bocconi on public.waitlist_signups;
create policy waitlist_signups_insert_bocconi on public.waitlist_signups
  for insert to anon, authenticated
  with check (
    lower(split_part(email::text, '@', 2)) = 'studbocconi.it'
    and status = 'new'
  );

insert into public.founder_circle_recruits (
  campus_id,
  slot,
  segment,
  circle_name,
  next_step
)
select
  c.id,
  slot,
  segment,
  circle_name,
  'find lead'
from public.campuses c
cross join (
  values
    (1, 'undergrad-first-years', 'first-year trusted five'),
    (2, 'exchange-students', 'exchange landing circle'),
    (3, 'msc-management', 'msc management circle'),
    (4, 'finance', 'finance study circle'),
    (5, 'marketing', 'marketing launch circle'),
    (6, 'law', 'law cohort circle'),
    (7, 'ai-builders', 'ai builders circle'),
    (8, 'design-ux', 'design and ux circle'),
    (9, 'entrepreneurship', 'founder builders circle'),
    (10, 'student-club-hosts', 'club host circle'),
    (11, 'residence', 'student residence circle'),
    (12, 'sports', 'sports team circle'),
    (13, 'music-events', 'music and events circle'),
    (14, 'international-students', 'international circle'),
    (15, 'scholarship-students', 'scholarship cohort circle'),
    (16, 'product-people', 'product feedback circle'),
    (17, 'consulting', 'consulting prep circle'),
    (18, 'creators', 'private creator circle'),
    (19, 'nightlife', 'orientation night circle'),
    (20, 'late-arrivals', 'late-arrival helper circle')
) as targets(slot, segment, circle_name)
where c.slug = 'bocconi'
on conflict do nothing;
