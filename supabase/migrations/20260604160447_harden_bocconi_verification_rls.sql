-- Harden public access for the latest MVP tables and make Bocconi verification
-- work without exposing founder invite codes through RLS.

create schema if not exists private;
revoke all on schema private from public;

revoke all on table
  public.reports,
  public.blocks,
  public.invites,
  public.campuses,
  public.founder_invite_codes,
  public.campus_verifications
from anon, authenticated;

grant select, insert on table public.reports to authenticated;
grant select, insert, delete on table public.blocks to authenticated;
grant select, insert, update on table public.invites to authenticated;
grant select on table public.campuses to authenticated;
grant insert, select, update on table public.campus_verifications to authenticated;

drop trigger if exists trg_campus_verification_guard on public.campus_verifications;
drop trigger if exists trg_campus_verification_count_code_use on public.campus_verifications;

drop function if exists public.campus_verification_count_code_use();
drop function if exists public.campus_verification_guard();

create or replace function private.campus_verification_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  campus_domain text;
  reserved_code_id uuid;
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

  if tg_op = 'UPDATE' and (
    new.campus_id <> old.campus_id
    or lower(new.founder_code::text) <> lower(old.founder_code::text)
  ) then
    raise exception 'campus verification code cannot be changed';
  end if;

  if tg_op = 'INSERT' then
    update public.founder_invite_codes
    set used_count = used_count + 1
    where campus_id = new.campus_id
      and lower(code::text) = lower(new.founder_code::text)
      and used_count < max_uses
      and (expires_at is null or expires_at > now())
    returning id into reserved_code_id;

    if reserved_code_id is null then
      raise exception 'invalid founder invite code';
    end if;
  end if;

  new.email = lower(new.email::text)::citext;
  new.founder_code = upper(new.founder_code::text)::citext;
  new.verified_at = now();
  return new;
end
$$;

revoke all on function private.campus_verification_guard() from public;

create trigger trg_campus_verification_guard
before insert or update on public.campus_verifications
for each row execute function private.campus_verification_guard();

drop policy if exists reports_select_own on public.reports;
create policy reports_select_own on public.reports
  for select to authenticated
  using (reporter_id = (select auth.uid()));

drop policy if exists reports_insert_own_visible_target on public.reports;
create policy reports_insert_own_visible_target on public.reports
  for insert to authenticated
  with check (
    reporter_id = (select auth.uid())
    and reported_user_id <> (select auth.uid())
    and (
      post_id is null
      or exists (
        select 1 from public.halo_posts p
        where p.id = reports.post_id
          and p.user_id = reports.reported_user_id
          and p.expires_at > now()
          and (
            p.user_id = (select auth.uid())
            or public.tier_rank(public.viewer_tier_towards(p.user_id))
               >= public.tier_rank(p.min_tier)
          )
      )
    )
  );

drop policy if exists blocks_select_own on public.blocks;
create policy blocks_select_own on public.blocks
  for select to authenticated
  using (blocker_id = (select auth.uid()));

drop policy if exists blocks_insert_own on public.blocks;
create policy blocks_insert_own on public.blocks
  for insert to authenticated
  with check (
    blocker_id = (select auth.uid())
    and blocked_user_id <> (select auth.uid())
  );

drop policy if exists blocks_delete_own on public.blocks;
create policy blocks_delete_own on public.blocks
  for delete to authenticated
  using (blocker_id = (select auth.uid()));

drop policy if exists invites_select_involved on public.invites;
create policy invites_select_involved on public.invites
  for select to authenticated
  using (
    inviter_id = (select auth.uid())
    or invitee_id = (select auth.uid())
  );

drop policy if exists invites_insert_own on public.invites;
create policy invites_insert_own on public.invites
  for insert to authenticated
  with check (
    inviter_id = (select auth.uid())
    and invitee_id <> (select auth.uid())
    and tier in ('inner', 'close')
    and status = 'pending'
  );

drop policy if exists invites_update_accept_or_owner_revoke on public.invites;
create policy invites_update_accept_or_owner_revoke on public.invites
  for update to authenticated
  using (
    inviter_id = (select auth.uid())
    or invitee_id = (select auth.uid())
  )
  with check (
    (
      inviter_id = (select auth.uid())
      and status in ('pending', 'revoked')
    )
    or (
      invitee_id = (select auth.uid())
      and status in ('accepted', 'declined')
    )
  );

drop policy if exists campuses_select_authenticated on public.campuses;
create policy campuses_select_authenticated on public.campuses
  for select to authenticated
  using (true);

drop policy if exists campus_verifications_select_own on public.campus_verifications;
create policy campus_verifications_select_own on public.campus_verifications
  for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists campus_verifications_insert_own on public.campus_verifications;
create policy campus_verifications_insert_own on public.campus_verifications
  for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists campus_verifications_update_own on public.campus_verifications;
create policy campus_verifications_update_own on public.campus_verifications
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
