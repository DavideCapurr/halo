# Swarm Halo — Consumer Variant Notes

> Roadmap note: this document records Halo consumerization notes for the
> SWARM family. The canonical Fase A anchors live in
> `docs/design-system/swarm-v1.md`: Halo may get warmer and more social here,
> but it still has to read as SWARM.

> **Estensione consumer di SWARM** per Halo. Eredita la grammatica del
> brand-book SWARM (palette mono · spacing · radii · motion · voice ·
> type families) e introduce due variazioni: palette **warm** (paper-cream
> su warm-black invece di platinum su absolute-black) e **single activation
> bronze** invece dei tre activation color SWARM (lime · purple · magenta).
>
> Halo è un prodotto consumer-social, non un operator surface. Le scelte
> qui sono pensate per restare coerenti con la famiglia SWARM mentre si
> consumerizza la superficie.
>
> **Source canonico corrente**: `docs/design-system/swarm-v1.md`.
> **Riferimento famiglia**: SWARM brand-book (esterno a questo repo).
> **Decisioni di vocabolario**: `docs/research/vocabulary.md`.
> **Ragionamento di direzione**: `docs/research/aesthetic-directions.md`.

## Come è cablato nel frontend iOS

```
docs/design-system/swarm-halo-v1.md            — canonical reference (questo file)
        │
        ▼
HaloApp/DesignSystem/Tokens.swift              — token extraction
        │
        ├──▶ HaloApp/DesignSystem/HaloTheme.swift          — thin wrapper backwards-compat
        ├──▶ HaloApp/DesignSystem/HaloTypography.swift     — type system su Cormorant/Inter/Plex Mono/Space Grotesk
        ├──▶ HaloApp/DesignSystem/HapticEngine.swift       — feedback per tier
        ├──▶ HaloApp/DesignSystem/MoodPalette.swift        — canale colore mood (OKLCH) — non collide con i token
        │
        ├──▶ HaloApp/Resources/Fonts/                      — .ttf bundle
        ├──▶ HaloApp/Info.plist (UIAppFonts)               — registrazione font
        │
        └──▶ HaloApp/Features/**/*.swift                   — ogni componente UI
```

## Differenze dichiarate vs SWARM brand-book

Cosa eredita letterale:

| Categoria | Eredita | Note |
|---|---|---|
| Spacing | sistema 4 / 8 fino a 128 | identico |
| Radii | 6 card · 4 input · 2 chip · 999 pill | identico |
| Motion easing | `cubic-bezier(0.2, 0.7, 0.1, 1)` | identico |
| Durations | 120ms tap · 320ms card mount · 4000ms breath · 900ms loader | adattato da SWARM |
| Iconografia | 24×24 grid · stroke-only 1.5px · round caps | identico |
| Voice rules | sentence case · periodi · numerali in cifre · em-dash · uppercase solo wordmark | identico (adattato all'italiano in `vocabulary.md` §9) |
| Type families | Cormorant Garamond · Inter (sostituisce Satoshi per licenza Google Fonts) · IBM Plex Mono · Space Grotesk | identico nelle 4 categorie |
| Token naming | `surface · ink · stroke · activation · radius · motion` | identico |

Cosa Halo customizza dentro la famiglia:

| Categoria | SWARM | Halo |
|---|---|---|
| Background | `absolute-black #000000` | `warm-black #0F0E10` |
| Ink primaria | `platinum #E8E8EA` | `paper-cream #E4DDCF` |
| Activation | 3 colori (lime · purple · magenta) | 1 colore: `bronze #A88260` + `warm-magenta #FF2B6E` (solo attention/error) |
| Type hero | scala SWARM Hero 144 | scala mobile-friendly max 72 |
| Surfaces | frame brand-book statici | **living surfaces** — bolle pulsanti, glow decay, ring breath |
| Eyebrow font | Space Grotesk uppercase tracked | Space Grotesk uppercase tracked (identico) |

Cosa Halo aggiunge come estensione:

- **Mood palette OKLCH** (`HaloApp/DesignSystem/MoodPalette.swift`). Canale
  di colore parallelo, dato dall'utente (vibe attiva), non dal sistema. Le
  bolle prendono il mood color; le UI prendono solo bronze. I due canali
  non collidono.
- **Glow decay** sul ritratto come funzione del tempo dall'ultima
  attività. SWARM non lo prevede; Halo lo rende parte del sistema.
- **Halo-as-noun**: il glow attorno al ritratto è letteralmente *il halo
  della persona*. Vedi `docs/research/vocabulary.md` §5. La metafora
  visiva ha peso semantico.

## Token summary

| Categoria | Token | Valore | Uso |
|---|---|---|---|
| Surface | `absoluteBlack` | `#000000` | raro, solo glow boundary |
| Surface | `warmBlack` | `#0F0E10` | background principale |
| Surface | `nightSurface` | `#161516` | card |
| Surface | `nightSurface2` | `#1B191A` | modal sheet |
| Surface | `nightEdge` | `#07070A` | separator |
| Ink | `paperCream` | `#E4DDCF` | testo primario |
| Ink | `creamLow` | `paperCream @ 0.62` | testo secondario |
| Ink | `creamMute` | `paperCream @ 0.42` | caption |
| Ink | `creamHair` | `paperCream @ 0.18` | hairline visibile |
| Ink | `creamLine` | `paperCream @ 0.10` | linea sottile |
| Ink | `creamWhisper` | `paperCream @ 0.06` | whisper/glass fill |
| Activation | `bronze` | `#A88260` | accent single-use per stato attivo |
| Activation | `bronzeSoft` | `bronze @ 0.55` | accent secondario |
| Activation | `bronzeGlow` | `bronze @ 0.35` | glow shadow |
| Attention | `warmMagenta` | `#FF2B6E` | error / downgrade / report (solo) |
| Stroke | `strokeRest` | `paperCream @ 0.12` | bordi card |
| Stroke | `strokeActive` | `paperCream @ 0.42` | bordi attivi |
| Radius | `radiusCard` | 6 | card |
| Radius | `radiusInput` | 4 | input |
| Radius | `radiusChip` | 2 | chip |
| Radius | `radiusPill` | 999 | pill |
| Spacing | `s1 … s32` | 4 · 8 · 12 · 16 · 24 · 32 · 48 · 64 · 96 · 128 | scala SWARM |
| Motion | `easeSwarm` | `cubic-bezier(0.2, 0.7, 0.1, 1)` | tutta la app |
| Motion | `tap` | 0.12s | feedback bottoni |
| Motion | `cardMount` | 0.32s | entrata card |
| Motion | `stagger` | 0.04s | offset tra card |
| Motion | `breath` | 4.0s | vibe pulse |
| Motion | `loader` | 0.9s | spinner |

## Type system

### Famiglie

| Famiglia | Postscript | Uso |
|---|---|---|
| Cormorant Garamond | `CormorantGaramond-Regular/Italic/Medium/MediumItalic` | display, headlines, nomi persona, vibe note, manifesto |
| Inter | `Inter-Regular/Medium/SemiBold` | UI, body, controlli, navigazione |
| IBM Plex Mono | `IBMPlexMono-Regular/Medium` | telemetria, timestamps, count, short labels |
| Space Grotesk | `SpaceGrotesk-Medium` | eyebrow micro-labels (UPPERCASE tracked) |

### Scala tipografica

| Token | px | Famiglia consigliata |
|---|---|---|
| `hero` | 72 | Cormorant Italic 400 |
| `h1` | 40 | Cormorant Italic / Regular 400 |
| `h2` | 28 | Cormorant Italic / Regular 400 |
| `h3` | 22 | Cormorant Italic 400 |
| `lede` | 17 | Inter Regular 400 |
| `body` | 15 | Inter Regular 400 |
| `ui` | 13 | Inter Medium 500 |
| `eyebrow` | 11 | Space Grotesk Medium 500 (uppercase, tracking 2.4-2.6) |
| `mono` | 12 | IBM Plex Mono Medium 500 (tracking 1.5-2.0) |
| `micro` | 9.5 | Space Grotesk Medium 500 (eyebrow) o IBM Plex Mono (timestamp) |

### Uso per superficie

| Superficie | Tipo |
|---|---|
| nome persona (orbit + halospace) | Cormorant Italic 22-28 |
| manifesto headline (welcome) | Cormorant Italic 36-72 |
| vibe note dentro la card | Cormorant Italic 17-22 |
| body copy (compose, sheet) | Inter Regular 15 |
| controlli (bottoni, tab) | Inter Medium 13 |
| eyebrow di sezione | Space Grotesk Medium 11 UPPERCASE |
| count e timestamp | IBM Plex Mono Medium 12-18 |
| telemetry strip (status bar) | IBM Plex Mono Medium 9.5 |

## Mapping stati Halo

Halo ha due canali di stato indipendenti — i due non collidono mai sulla
stessa superficie.

### Canale 1 — Stati di sistema (mappati su SWARM activation, ma single-bronze)

| Stato sistema | SWARM equivalent | Halo color | Uso |
|---|---|---|---|
| rest (Nebula) | rest (no halo) | `creamHair` | bordo bolla, nessun glow |
| visible-rest (Orbit) | rest (light hairline) | `creamLow` border | bordo più visibile, nessun glow |
| active (Inner / Close attivo) | connected (lime) | `bronze` glow | il halo della persona |
| attention (errore / downgrade / report) | attention (magenta) | `warmMagenta` | usato solo per stati di errore reali |

### Canale 2 — Stati di mood (vibe utente)

Mood palette OKLCH (`MoodPalette.swift`), già implementata. Otto mood
(chill, wild, lost, focused, warm, electric, blue, soft) → colori derivati
matematicamente con hue e chroma per-mood, luminanza variabile.

I mood colors si applicano:

- come **glow** attorno alla bolla quando la vibe è attiva (`auraRing`)
- come **chip color** quando il mood è selezionato in compose
- come **tint sottile** dello sfondo quando un mood domina nelle prime
  card visibili del Pulse

I mood non collidono con il canale di sistema perché vivono su livello
visivo diverso (glow vs stroke vs fill secondario), e perché sono dati
dall'utente non dallo stato dell'app.

## Iconografia

- Griglia 24×24 px
- Tutte stroke-only, 1.5 px line
- Caps round, joins round
- Colore default: `creamLow` (62%)
- Stato attivo: `paperCream` (100%) o `bronze` se segnala azione
- Disegno SF Symbols quando un equivalente diretto esiste; custom Canvas
  altrimenti (vedi `ReactionGlyph.swift`)

## Voice rules — extract (vedi `vocabulary.md` §9 per la versione completa)

- Sentence case in body e headline. Eyebrow e telemetry mono possono
  essere uppercase con tracking.
- Periodi come armi. Mai esclamativi (mai mai).
- Numerali in cifre, non in lettere. Pad con zero quando è sequenza
  (`001 · 007 · 042`).
- Em-dash per pivot. Middle dot (`·`) per separare token in stessa riga.
- Mai "tu", "voi", "noi", "Lei". Imperativo italiano diretto.
- Wordmark = solo posto in cui appare maiuscolo intero. Tutto il resto è
  sentence case.

## Living surfaces — estensione consumer

SWARM brand-book mostra frame statici. Halo aggiunge superfici in
movimento ambient. Sono parte del design system, non extra decorativo.

| Superficie | Motion | Spec |
|---|---|---|
| Bolla persona (vibe attiva) | pulse breath | scale `1.0 → 1.03 → 1.0` su 4000ms, glow `bronze @ 0.35 → 0.15 → 0.35`, easeSwarm in/out |
| Decay ring (post che invecchia) | progress | radius della scia diminuisce da 360° a 0° in 72h (lineare) |
| Card mount (feed) | stagger | offset `y +12 → 0` + opacity `0 → 1` su 320ms con stagger 40ms |
| Self center (orbital home) | breath subliminale | scale `1.0 → 1.015 → 1.0` su 6s (più lento del vibe pulse, mai distrae) |
| Tab change | none | snap istantaneo (UI tactical, non ambient) |
| Sheet present | slide + fade | translateY 100% → 0 + opacity 0 → 1 su 420ms easeSwarm |

## Quando il design system si aggiorna

1. Modifica questo file (`docs/design-system/swarm-halo-v1.md`) o aggiungi
   un addendum `v2.md` accanto.
2. Aggiorna `HaloApp/DesignSystem/Tokens.swift` con i nuovi valori
   semantici.
3. Refactor componenti coinvolti (lavoro normale, niente magic).
4. Aggiorna il PLAN.md (Fase 9 polish) se cambia la voce o il lessico.
