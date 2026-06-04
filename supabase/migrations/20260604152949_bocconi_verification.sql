-- Bocconi cold-start verification.
-- MVP access model: a user proves Bocconi scope by entering a @studbocconi.it
-- email plus an offline founder code. Email OTP can be layered on later.

create table if not exists public.campuses (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique,
  name          text not null,
  email_domain  text not null,
  created_at    timestamptz not null default now()
);

create table if not exists public.founder_invite_codes (
  id          uuid primary key default gen_random_uuid(),
  campus_id   uuid not null references public.campuses(id) on delete cascade,
  code        citext not null unique,
  label       text,
  max_uses    integer not null default 20 check (max_uses > 0),
  used_count  integer not null default 0 check (used_count >= 0),
  expires_at  timestamptz,
  created_at  timestamptz not null default now()
);

create index if not exists founder_invite_codes_campus_idx
  on public.founder_invite_codes (campus_id);

create table if not exists public.campus_verifications (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  campus_id     uuid not null references public.campuses(id) on delete cascade,
  email         citext not null,
  founder_code  citext not null,
  verified_at   timestamptz not null default now(),
  created_at    timestamptz not null default now(),
  unique (user_id, campus_id),
  check (email ~* '^[^@[:space:]]+@[^@[:space:]]+$')
);

create index if not exists campus_verifications_campus_idx
  on public.campus_verifications (campus_id, verified_at desc);

insert into public.campuses (slug, name, email_domain)
values ('bocconi', 'Universita Bocconi', 'studbocconi.it')
on conflict (slug) do update
set name = excluded.name,
    email_domain = excluded.email_domain;

insert into public.founder_invite_codes (campus_id, code, label, max_uses)
select id, 'BOCCONI-FOUNDERS-2026', 'Founder circles offline launch', 200
from public.campuses
where slug = 'bocconi'
on conflict (code) do nothing;

create or replace function public.campus_verification_guard()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  campus_domain text;
  code_row public.founder_invite_codes%rowtype;
begin
  select email_domain
    into campus_domain
  from public.campuses
  where id = new.campus_id;

  if campus_domain is null then
    raise exception 'campus not found';
  end if;

  if lower(split_part(new.email::text, '@', 2)) <> lower(campus_domain) then
    raise exception 'email domain is not allowed for this campus';
  end if;

  select *
    into code_row
  from public.founder_invite_codes
  where campus_id = new.campus_id
    and lower(code::text) = lower(new.founder_code::text)
    and used_count < max_uses
    and (expires_at is null or expires_at > now())
  limit 1;

  if code_row.id is null then
    raise exception 'invalid founder invite code';
  end if;

  new.email = lower(new.email::text)::citext;
  new.founder_code = upper(new.founder_code::text)::citext;
  new.verified_at = now();
  return new;
end
$$;

drop trigger if exists trg_campus_verification_guard on public.campus_verifications;
create trigger trg_campus_verification_guard
before insert or update on public.campus_verifications
for each row execute function public.campus_verification_guard();

create or replace function public.campus_verification_count_code_use()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.founder_invite_codes
  set used_count = used_count + 1
  where campus_id = new.campus_id
    and lower(code::text) = lower(new.founder_code::text);
  return new;
end
$$;

drop trigger if exists trg_campus_verification_count_code_use on public.campus_verifications;
create trigger trg_campus_verification_count_code_use
after insert on public.campus_verifications
for each row execute function public.campus_verification_count_code_use();

alter table public.campuses enable row level security;
alter table public.founder_invite_codes enable row level security;
alter table public.campus_verifications enable row level security;

grant select on table public.campuses to authenticated;
grant insert, select, update on table public.campus_verifications to authenticated;

drop policy if exists campuses_select_authenticated on public.campuses;
create policy campuses_select_authenticated on public.campuses
  for select to authenticated
  using (true);

drop policy if exists campus_verifications_select_own on public.campus_verifications;
create policy campus_verifications_select_own on public.campus_verifications
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists campus_verifications_insert_own on public.campus_verifications;
create policy campus_verifications_insert_own on public.campus_verifications
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.founder_invite_codes c
      where c.campus_id = campus_verifications.campus_id
        and lower(c.code::text) = lower(campus_verifications.founder_code::text)
        and c.used_count < c.max_uses
        and (c.expires_at is null or c.expires_at > now())
    )
  );

drop policy if exists campus_verifications_update_own on public.campus_verifications;
create policy campus_verifications_update_own on public.campus_verifications
  for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.founder_invite_codes c
      where c.campus_id = campus_verifications.campus_id
        and lower(c.code::text) = lower(campus_verifications.founder_code::text)
        and c.used_count < c.max_uses
        and (c.expires_at is null or c.expires_at > now())
    )
  );
