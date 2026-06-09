# Halo Bocconi landing

Static landing page for the Bocconi cold-start slice.

## Files

- `index.html` - landing, waitlist forms, Founder Circles and orientation QR sections.
- `styles.css` - standalone responsive visual system.
- `script.js` - waitlist validation and submit behavior.
- `assets/orientation-ring-qr.png` - QR for `halo://ring/join/bocconi-orientation-week`.
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

The static QR points to:

```text
halo://ring/join/bocconi-orientation-week
```

The local seed creates a matching Event Ring with the same join token. In
production, create or refresh the Event Ring inside `EventRingView` and replace
the static QR asset if the token changes.
