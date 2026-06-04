-- Formal Inner invites. The invite mirrors the existing tier proposal flow:
-- inviter follows invitee at nebula, proposes a closer tier, and the invitee
-- accepts through a tokenized deep link.

create table if not exists public.invites (
  id          uuid primary key default gen_random_uuid(),
  token       text not null unique default encode(gen_random_bytes(16), 'hex'),
  inviter_id  uuid not null references public.profiles(id) on delete cascade,
  invitee_id  uuid not null references public.profiles(id) on delete cascade,
  tier        friendship_tier not null default 'inner',
  message     text check (char_length(coalesce(message, '')) <= 160),
  status      text not null default 'pending'
              check (status in ('pending', 'accepted', 'declined', 'revoked', 'expired')),
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null default (now() + interval '14 days'),
  accepted_at timestamptz,
  check (inviter_id <> invitee_id),
  check (tier in ('inner', 'close'))
);

create index if not exists invites_inviter_created_idx
  on public.invites (inviter_id, created_at desc);

create index if not exists invites_invitee_status_idx
  on public.invites (invitee_id, status, created_at desc);

create index if not exists invites_token_pending_idx
  on public.invites (token)
  where status = 'pending';

alter table public.invites enable row level security;

grant select, insert, update on table public.invites to authenticated;

drop policy if exists invites_select_involved on public.invites;
create policy invites_select_involved on public.invites
  for select to authenticated
  using (
    inviter_id = auth.uid()
    or invitee_id = auth.uid()
  );

drop policy if exists invites_insert_own on public.invites;
create policy invites_insert_own on public.invites
  for insert to authenticated
  with check (
    inviter_id = auth.uid()
    and invitee_id <> auth.uid()
    and tier in ('inner', 'close')
    and status = 'pending'
  );

drop policy if exists invites_update_accept_or_owner_revoke on public.invites;
create policy invites_update_accept_or_owner_revoke on public.invites
  for update to authenticated
  using (
    inviter_id = auth.uid()
    or invitee_id = auth.uid()
  )
  with check (
    (
      inviter_id = auth.uid()
      and status in ('pending', 'revoked')
    )
    or (
      invitee_id = auth.uid()
      and status in ('accepted', 'declined')
    )
  );
