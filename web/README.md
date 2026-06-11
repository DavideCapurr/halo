# Halo Campaigns — public web landing

Public, anyone-can-open landing for Halo penny campaigns. This is the "true Mike
Hayes reach" surface: non-Halo users open a campaign link and donate via Stripe
Checkout. Halo never touches the money — Checkout creates a direct charge on the
creator's connected account with the platform application fee.

## How it works

- `app/c/[slug]/page.tsx` reads the campaign through the anon-readable Supabase
  RPCs `public_campaign_by_slug` / `public_campaign_supporters` (only public,
  non-draft campaigns are exposed).
- `DonateButton` calls the `campaign-create-payment` Edge Function with
  `mode: "checkout"` and redirects to the hosted Stripe Checkout page
  (Apple Pay / Google Pay / Link / card). On return, `?status=success|cancel`
  shows a banner; the `stripe-webhook` function marks the contribution paid and
  the DB trigger updates the totals.

## Env

Copy `.env.example` to `.env.local` and set:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

The Edge Functions and their Stripe secrets live in Supabase, not here.

## Local dev

```bash
cd web
npm install
npm run dev          # http://localhost:3000/c/<public_slug>
```

## Deploy on Vercel

- Import the repo, set **Root Directory** to `web`.
- Framework preset: Next.js (auto-detected).
- Add the two `NEXT_PUBLIC_*` env vars.
- Point your campaign domain (e.g. `https://halo.app/c/<slug>`) here, and set the
  iOS `HALO_WEB_BASE_URL` build setting to the same origin so in-app shares use
  the public web link.
