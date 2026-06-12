# Halo - iOS MVP

Private social map basata su presenza umana e distanza relazionale.
Il beachhead e Bocconi, ma il modello resta globale: `Inner`, `Close`,
`Orbit` e `Nebula` governano quanto lontano viaggiano vibe e momenti.

Stack attuale: iOS 17+, SwiftUI, Supabase, WidgetKit e pacchetto locale
`HaloShared`.

## Stato attuale

Il repo ha superato il bootstrap iniziale:

- Progetto Xcode con target app, widget extension e package condiviso
  `HaloShared`.
- Backend Supabase con schema, RLS, seed, trigger tier, profili pubblici,
  indice mutualita e funzione `purge-expired`.
- Service layer Swift per auth, profili, follow, vibe, post, reazioni,
  storage, realtime feed e snapshot widget.
- Design system e componenti orbitali gia presenti, ma ancora da
  riallineare al brief SWARM canonico di Fase A.
- Flussi iOS gia presenti per sign in, onboarding, Initial Inner Circle,
  Orbit Home, Pulse, compose vibe-first, HaloSpace e widget.

### Stato rispetto alla roadmap A-E

La fase attiva e **Fase A - Adozione SWARM design**:

- `docs/design-system/swarm-v1.md` e il brief SWARM canonico.
- Swarm Halo resta una variante consumer e piu sociale, ma la parentela
  SWARM deve leggersi subito.
- Il codice corrente pende ancora troppo verso cream/bronze, type mapping
  non ancora SWARM completo e alcuni hex da riportare a token.
- I gap prodotto HALO PDF (Rings, invite, Bocconi verify, reports,
  Memory, Events/Clubs) entrano in Fase B.

### Stato da non confondere con "finito"

La UI principale e ancora in transizione da prototipo a prodotto live, ma il
gap demo/live del feed Home/Pulse e stato chiuso:

- `HomeView` e `Pulse` usano `HomeViewModel.feedItems`/`MomentItem` reali come
  sorgente visibile; `SeedPeople` resta per preview e bootstrap `.seed`.
- `FeedViewModel` in `.live` idrata post e reazioni reali, poi applica patch
  realtime mirate per post, vibe e reazioni invece di ricaricare tutto.
- `MomentCard` e le card Pulse leggono `PostKind`, caption, scadenza e
  aggregati reazione dal backend; le anteprime/reazioni deterministiche sono
  limitate al percorso seed/preview.
- `ProfileView`, il vecchio `ComposePostView` e Halo Plus/StoreKit hanno
  ancora placeholder o TODO.
- Dal brief strategico PDF mancano ancora pezzi MVP importanti:
  Event Halo con QR/invite token, Memory Halo+ e analytics di attivazione.

`PLAN.md` traccia il lavoro implementativo gia fatto e le scelte prese,
ma va letto insieme al codice quando una checkbox riguarda feature ancora
placeholder fuori dal feed.

## Prossimo slice consigliato

Partire da Fase A:

1. Portare `Tokens.swift` alla palette mono+activation, spacing, radii e
   motion SWARM.
2. Riallineare `HaloTypography.swift` ai 4 font e alla type scale SWARM.
3. Definire il mapping stati Halo/SWARM e rifare i componenti chiave
   dell'orbita e del Pulse sopra quei token.

I gap prodotto del PDF restano visibili, ma il wiring live di Orbit/Pulse non
e piu il blocco principale del feed.

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
scripts/           — utility dev (es. demo-screens.sh)
```

## Verifica grafica / Demo mode

Per ispezionare l'UI con contenuti realistici senza backend né auth, l'app ha
una **demo mode offline** attivata via env var (zero impatto in produzione —
vedi `DemoMode` in `HaloApp/App/AppState.swift`):

- `HALO_DEMO=1` — bypassa auth/Supabase e idrata le schermate da `SeedPeople`
- `HALO_DEMO_TAB=orbit|pulse|status|profile` — tab iniziale
- `HALO_DEMO_SHEET=compose|vibe|easy|space` — sheet auto-presentata

Cattura tutte le superfici principali in un colpo solo:

```sh
./scripts/demo-screens.sh            # usa il simulatore booted (o iPhone 17 Pro)
OUT=/tmp/shots ./scripts/demo-screens.sh
```

Gli screenshot finiscono in `/tmp/halo-shots/` (override con `OUT=`).

## Riferimenti

- `Halo_Strategy_App_Technical_Plan.pdf`: strategia prodotto, MVP criteria
  e roadmap.
- `PLAN.md`: piano implementativo locale.
- `docs/design-system/swarm-v1.md`: brief SWARM canonico per Fase A.
- `docs/design-system/swarm-halo-v1.md`: note consumer di Swarm Halo.
- `docs/research/`: vocabolario, audit competitivo e direzioni estetiche.
