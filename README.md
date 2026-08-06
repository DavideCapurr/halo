# Halo - iOS MVP

**Halo è la rete delle persone che hai incontrato davvero.** Non chi ti segue,
non chi conosci online: chi hai incontrato. L'evento è la porta (Ring + QR),
la presenza è il pavimento (widget e vibe).

> **Leggi prima `docs/PRODOTTO.md`** — tesi, moat, loop, cosa è core e cosa è
> impalcatura Bocconi, e le cinque domande con cui si giudica ogni feature.
> Questo README descrive *com'è fatto* il repo; quel file descrive *perché*.

Bocconi è il trampolino, non il prodotto: la verifica campus è un acceleratore
locale, la prova di co-presenza è il core che generalizza. `Inner`, `Close`,
`Orbit` e `Nebula` restano l'idraulica che governa quanto lontano viaggiano
vibe e momenti — idraulica invisibile, non pannello di controllo.

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
- Design system e componenti orbitali gia presenti, da riallineare alla
  direzione canonica in `docs/DESIGN.md`.
- Flussi iOS gia presenti per sign in, onboarding, Initial Inner Circle,
  Orbit Home, Pulse, compose vibe-first, HaloSpace e widget.

### Stato rispetto alla roadmap A-E

La fase attiva e **validazione della tesi** (`docs/PRODOTTO.md` §10): il
prossimo deliverable non e codice, e capire se il problema esiste.

- **Fase A (adozione SWARM) e chiusa, non completata.** L'ereditarieta SWARM
  e uscita dai vincoli di Halo — motivo in `docs/DESIGN.md` §2. I brief sono
  in `docs/archive/`.
- `docs/DESIGN.md` e la direzione visiva canonica: guscio premium, atto
  banale; nessun accent di brand, il colore viene dalle persone.
- Il lavoro visivo residuo (invertire `MoodPalette`, un font solo, togliere
  gli alias legacy in `Tokens.swift`) e in `PLAN.md`.

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

**Non e codice.** Il rischio dominante e domanda e ritorno, non feature
mancanti: vedi `docs/PRODOTTO.md` §10 per la domanda da fare e
`docs/DESIGN.md` §6 per come si verifica la direzione visiva in parallelo.

Quando si torna al codice, l'ordine e:

1. Invertire `MoodPalette.swift` da canale secondario a fondamento del colore.
2. Collassare `HaloTypography.swift` su una famiglia sola.
3. Rimuovere gli alias legacy in `Tokens.swift`.
4. Togliere `ChooseYourFiveView` dall'onboarding: i tier vanno derivati dal
   comportamento (`docs/PRODOTTO.md` §7).

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

La build configuration di produzione vive in `Config/` come file `.xcconfig`,
single source of truth condiviso da app e widget (niente più valori sparsi
nelle Build Settings del `.pbxproj`):

- `Config/Shared.xcconfig` — `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `APP_GROUP_ID`
  (ereditati sia da `HaloApp` sia da `HaloWidget`)
- `Config/HaloApp.xcconfig` — include `Shared` + `HALO_URL_SCHEME`
- `Config/HaloWidget.xcconfig` — include `Shared`

Per puntare a un altro progetto Supabase basta cambiare i valori in
`Config/Shared.xcconfig` (la anon key è publishable: ok in repo). Nota
xcconfig: gli URL vanno spezzati con `$()` (es. `https:/$()/host`) perché
`//` introduce un commento.

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
- `docs/PRODOTTO.md`: **tesi, moat, loop, core vs impalcatura.** Da leggere
  per primo — spiega perche tutto il resto esiste.
- `docs/DESIGN.md`: direzione visiva canonica e le cinque regole di stile.
- `PLAN.md`: piano implementativo locale.
- `docs/research/`: vocabolario e audit competitivo.
- `docs/archive/`: brief SWARM e direzioni estetiche superate. Storia, non
  riferimento.
