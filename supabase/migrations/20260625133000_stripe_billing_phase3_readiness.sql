-- Phase 3 billing readiness: Stripe customer persistence and explicit grants
-- for server-side Edge Functions under Supabase's opt-in Data API exposure.

alter table public.subscriptions
  add column if not exists provider_customer_id text;

alter table public.club_billing
  add column if not exists provider_customer_id text;

create index if not exists subscriptions_provider_customer_idx
  on public.subscriptions (provider, provider_customer_id, updated_at desc)
  where provider_customer_id is not null;

create index if not exists club_billing_provider_customer_idx
  on public.club_billing (provider, provider_customer_id, created_at desc)
  where provider_customer_id is not null;

grant select, insert, update, delete on table public.rings to service_role;
grant select, insert, update, delete on table public.ring_members to service_role;
grant select, insert, update, delete on table public.event_checkins to service_role;
grant select, insert, update, delete on table public.subscriptions to service_role;
grant select, insert, update, delete on table public.club_billing to service_role;

grant execute on function public.is_ring_member(uuid, uuid) to service_role;
grant execute on function public.can_manage_ring(uuid, uuid) to service_role;
grant execute on function public.join_ring_by_token(text) to service_role;
grant execute on function public.join_public_ring(uuid) to service_role;
grant execute on function public.refresh_ring_join_token(uuid) to service_role;
grant execute on function public.check_in_event_ring(uuid) to service_role;
