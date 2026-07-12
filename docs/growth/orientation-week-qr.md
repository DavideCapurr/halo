# Orientation week QR Event Ring

The cold-start QR now targets an **https universal link**, not the raw
`halo://` scheme. A student who scans without the app installed no longer hits a
dead end: iOS opens the app directly when it is present (Associated Domains),
and the join page falls back to TestFlight otherwise — keeping the ring token.

QR target (replace `<dominio>` with the real landing domain):

```text
https://<dominio>/join/?ring=bocconi-orientation-week
```

The old `halo://ring/join/bocconi-orientation-week` still parses in-app, so any
already-printed material keeps working for people who have the app — but the
QR you print for the orientation week must encode the https link above.

Static landing assets:

```text
web/landing/join/index.html                          # join bridge (open app / TestFlight)
web/landing/.well-known/apple-app-site-association    # AASA for universal links
web/landing/assets/orientation-ring-qr.png            # QR image — regenerate to the https link
```

> The committed `orientation-ring-qr.png` still encodes the legacy `halo://`
> URL. Regenerate it (and any print material) from the https link before the
> orientation week.

Local seeded Event Ring:

```text
Orientation week / Bocconi
```

## Universal link setup (before launch)

1. Point the landing domain (the one in the QR) at `web/landing/`.
2. Serve `apple-app-site-association` from `/.well-known/` as
   `application/json`, no file extension, over https with no redirects.
3. In the app entitlements replace the placeholder host in
   `applinks:halo.app` (`HaloApp/HaloApp.entitlements`) with the real domain,
   and set the real Team ID + bundle ID in the AASA `appIDs`.
4. Set `TESTFLIGHT_URL` in `web/landing/join/index.html` to the public
   TestFlight link once the beta is live.

The token flows end to end: the join page opens `halo://ring/join/<token>`,
`DeepLink(url:)` parses it (both the https and scheme forms), and
`AppState.handle(link:)` routes to the ring after auth/onboarding.

## In-app flow

1. Open Profile.
2. Tap `Event Ring`.
3. Use the orientation quick action or create an Event Ring manually.
4. Share or print the QR shown in `EventRingView`.
5. Students scan the QR, join the ring, and check in.

## Print copy

```text
Scan.
Join the ring.
Be there.
```

## Host checklist

- Print one QR per table or room entrance.
- Keep one phone open on `EventRingView` for live check-in count.
- Ask each Founder Circle to scan together.
- Mark the matching row in `docs/growth/founder-circles-tracker.csv`.
- Send the 48-hour feedback prompt after the event.
