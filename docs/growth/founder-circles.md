# Founder Circles recruiting kit

Goal: recruit 20 Bocconi Founder Circles before and during orientation week.
Each circle is one trusted lead plus four people who already know each other.

## Target

| Metric | Target |
| --- | ---: |
| Founder Circles recruited | 20 |
| People per circle | 5 |
| Activated students | 100 |
| First scan to first check-in | under 10 minutes |
| Follow-up feedback loops | 20 within 48 hours |

## Qualification rule

A Founder Circle counts only when all of these are true:

- The lead uses a `@studbocconi.it` email.
- The lead has the founder invite code path ready.
- At least five real people agree to join the same circle.
- The circle scans an Event Ring QR together.
- One person sends feedback within 48 hours.

## Offline channels

- Orientation queues: catch people while they already wait together.
- Club tables: recruit hosts who can bring a trusted micro-group.
- Library and study rooms: ask for existing project groups, not random singles.
- Residence and exchange meetups: target students who need fast context.
- Founder/builders pockets: pitch Halo as private feedback and proximity, not audience growth.

## One-minute script

```text
Halo is a private social map for campus.
It is not a feed and it is not for followers.

We are starting with 20 Founder Circles at Bocconi:
you plus four people you already trust.
Scan one QR, join the same Event Ring, and we use your feedback to shape launch.

If you want in, use your @studbocconi.it email and the founder code.
I will follow up within 48 hours and ask what felt useful or awkward.
```

## Founder code

Default local code:

```text
BOCCONI-FOUNDERS-2026
```

The app verification path is already wired through
`CampusVerificationService` and `BocconiVerifyView`.

## Operating loop

1. Fill one row in `docs/growth/founder-circles-tracker.csv`.
2. Create or reuse the `Orientation week / Bocconi` Event Ring.
3. Have the circle scan the QR together.
4. Confirm at least one successful check-in.
5. Send the 48-hour feedback prompt.
6. Move the row to `activated` only after feedback lands.

## 48-hour feedback prompt

```text
You scanned Halo during orientation.
What made the ring feel useful, what felt unclear, and who would you add to your five?
One honest paragraph is enough.
```

## Status values

- `target` - segment identified, no person committed yet.
- `pitched` - lead heard the pitch.
- `committed` - lead agreed to bring four people.
- `scanned` - circle scanned an Event Ring QR.
- `activated` - scanned plus feedback received.
- `dropped` - no follow-up after two attempts.
