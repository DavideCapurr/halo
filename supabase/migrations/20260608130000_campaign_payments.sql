-- Stripe Connect accounts for campaign creators.
--
-- One connected account per creator (Express). Donations are *direct charges*
-- on this account: funds settle straight into the creator's Stripe balance and
-- Halo only takes an application fee — Halo never holds the money. This table is
-- written exclusively by the Edge Functions / webhook (service role); clients can
-- only read their own row to know whether onboarding is complete.

create table if not exists public.stripe_accounts (
  user_id           uuid primary key references public.profiles(id) on delete cascade,
  stripe_account_id text not null unique,
  charges_enabled   boolean not null default false,
  payouts_enabled   boolean not null default false,
  details_submitted boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

drop trigger if exists trg_stripe_accounts_touch_updated_at on public.stripe_accounts;
create trigger trg_stripe_accounts_touch_updated_at
before update on public.stripe_accounts
for each row execute function public.rings_touch_updated_at();

alter table public.stripe_accounts enable row level security;

grant select on table public.stripe_accounts to authenticated;

-- Read-only, own row only. All writes happen with the service role from the
-- Stripe Edge Functions / webhook, which bypass RLS.
drop policy if exists stripe_accounts_select_self on public.stripe_accounts;
create policy stripe_accounts_select_self on public.stripe_accounts
  for select to authenticated
  using (user_id = auth.uid());
