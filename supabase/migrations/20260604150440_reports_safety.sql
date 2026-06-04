-- Halo safety MVP: user reports + personal blocks.
-- Reports are visible only to the reporter through the public client; service
-- role/admin tooling can review all rows outside RLS.

do $$ begin
  create type report_reason_enum as enum (
    'harassment',
    'spam',
    'impersonation',
    'unsafe',
    'other'
  );
exception when duplicate_object then null; end $$;

create table if not exists public.reports (
  id                uuid primary key default gen_random_uuid(),
  reporter_id       uuid not null references public.profiles(id) on delete cascade,
  reported_user_id  uuid not null references public.profiles(id) on delete cascade,
  post_id           uuid references public.halo_posts(id) on delete set null,
  reason            report_reason_enum not null,
  details           text check (char_length(coalesce(details, '')) <= 500),
  status            text not null default 'open'
                    check (status in ('open', 'reviewed', 'dismissed', 'actioned')),
  created_at        timestamptz not null default now(),
  check (reporter_id <> reported_user_id)
);

create index if not exists reports_reporter_created_idx
  on public.reports (reporter_id, created_at desc);

create index if not exists reports_reported_status_idx
  on public.reports (reported_user_id, status, created_at desc);

create table if not exists public.blocks (
  blocker_id       uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id  uuid not null references public.profiles(id) on delete cascade,
  created_at       timestamptz not null default now(),
  primary key (blocker_id, blocked_user_id),
  check (blocker_id <> blocked_user_id)
);

create index if not exists blocks_blocked_user_idx
  on public.blocks (blocked_user_id);

alter table public.reports enable row level security;
alter table public.blocks  enable row level security;

grant select, insert on table public.reports to authenticated;
grant select, insert, delete on table public.blocks to authenticated;

drop policy if exists reports_select_own on public.reports;
create policy reports_select_own on public.reports
  for select to authenticated
  using (reporter_id = auth.uid());

drop policy if exists reports_insert_own_visible_target on public.reports;
create policy reports_insert_own_visible_target on public.reports
  for insert to authenticated
  with check (
    reporter_id = auth.uid()
    and reported_user_id <> auth.uid()
    and (
      post_id is null
      or exists (
        select 1 from public.halo_posts p
        where p.id = reports.post_id
          and p.user_id = reports.reported_user_id
          and p.expires_at > now()
          and (
            p.user_id = auth.uid()
            or public.tier_rank(public.viewer_tier_towards(p.user_id))
               >= public.tier_rank(p.min_tier)
          )
      )
    )
  );

drop policy if exists blocks_select_own on public.blocks;
create policy blocks_select_own on public.blocks
  for select to authenticated
  using (blocker_id = auth.uid());

drop policy if exists blocks_insert_own on public.blocks;
create policy blocks_insert_own on public.blocks
  for insert to authenticated
  with check (
    blocker_id = auth.uid()
    and blocked_user_id <> auth.uid()
  );

drop policy if exists blocks_delete_own on public.blocks;
create policy blocks_delete_own on public.blocks
  for delete to authenticated
  using (blocker_id = auth.uid());
