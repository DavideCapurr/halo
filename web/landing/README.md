# Halo Bocconi landing

Static landing page for the Bocconi cold-start slice.

## Files

- `index.html` - landing, waitlist forms, Founder Circles and orientation QR sections.
- `join/index.html` - QR join bridge: opens the app (universal link / scheme) or
  falls back to TestFlight, preserving the ring token.
- `.well-known/apple-app-site-association` - AASA for universal links (placeholder
  Team ID + bundle ID + domain to fill in before launch).
- `styles.css` - standalone responsive visual system.
- `script.js` - waitlist validation and submit behavior.
- `assets/orientation-ring-qr.png` - QR image (regenerate to the https join link).
- `assets/orientation-qr-hero.png` - generated hero product visual.
- `assets/landing-concept.png` - generated implementation concept.

## Waitlist endpoint

Deploy the Supabase function in `supabase/functions/waitlist-signup`, then set
the endpoint on both waitlist forms:

```html
<form data-waitlist-form data-endpoint="https://<project>.supabase.co/functions/v1/waitlist-signup">
```

For local preview, the forms validate `@studbocconi.it` emails and save rows in
`localStorage` when no endpoint is configured.

## Orientation QR

The QR now points to an https universal link handled by `join/index.html`:

```text
https://<domain>/join/?ring=bocconi-orientation-week
```

If the app is installed, iOS opens it directly (Associated Domains); otherwise
the join page sends the user to TestFlight while keeping the ring token. See
`docs/growth/orientation-week-qr.md` for the full setup (AASA hosting,
entitlement domain, TestFlight URL) and regenerate the QR asset to the https
link before printing.

The local seed creates a matching Event Ring with the same join token. In
production, create or refresh the Event Ring inside `EventRingView` and replace
the static QR asset if the token changes.
