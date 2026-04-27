# Halo — MVP v1

Social network basato su presenza umana a cerchi concentrici. iOS 17+, SwiftUI, Supabase.

## Stato attuale

Bootstrap scaffolding (step 1–2 del piano):
- Progetto Xcode standard (`Halo.xcodeproj`) con target app + widget extension + pacchetto locale `HaloShared`.
- Migrations Postgres (`supabase/migrations/0001_init.sql`, `0002_rls.sql`, `0003_tier_triggers.sql`).
- `seed.sql` con 8 profili tier mix.
- Edge function `purge-expired`.
- Placeholder Swift per i file chiave descritti nel piano.

Step 3+ (design system, auth, home orbital field, widget, IAP…) da implementare nei prossimi commit.

## Setup dev

Requisiti locali: macOS 14+, Xcode 15+, `supabase` CLI.

```bash
brew install supabase/tap/supabase

# 1. Supabase locale
supabase start
supabase db reset   # applica migrations + seed.sql

# 2. Progetto Xcode
open Halo.xcodeproj
```

Poi in Xcode apri il target `HaloApp` e imposta i valori in `Build Settings`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `APP_GROUP_ID`
- `HALO_URL_SCHEME`

Per il target `HaloWidget` imposta almeno:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `APP_GROUP_ID`

## Architettura (riassunto)

- **Client**: SwiftUI puro, `@Observable`, `Canvas` + `TimelineView` per l'orbital field, `WidgetKit` per lockscreen/StandBy, `StoreKit 2` per Halo Plus.
- **Backend**: Supabase (Postgres + Auth + Realtime + Storage + Edge Functions).
- **Privacy model**: RLS filtra `halo_posts` per `friendship_tier` (`nebula < orbit < close < inner`) via `tier_rank()`.

## Tier di amicizia

| Tier   | Cap (soft) | Vede                                                       |
|--------|------------|------------------------------------------------------------|
| Inner  | 5          | vibe + tutti i post + audio + reazioni in chiaro           |
| Close  | 15         | vibe + post foto/testo/audio + reazioni in chiaro          |
| Orbit  | ~50        | vibe + post target Orbit+ (no audio) + reazioni aggregate  |
| Nebula | illimitato | presenza + bio + handle + avatar                           |

I cap sono enforced via trigger come warning soft (non rifiutano l'INSERT ma segnalano — vedi `0003_tier_triggers.sql`).

## Struttura

```
HaloApp/           — main app target (SwiftUI)
HaloWidget/        — widget extension (lockscreen + StandBy)
HaloShared/        — Swift package condiviso (models + supabase lite client)
supabase/          — migrations, functions, seed
```

Dettagli nel piano interno.
