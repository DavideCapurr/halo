# Halo — direzioni estetiche

> Tre direzioni a confronto, valutate per il target Bocconiano, con il
> vincolo che **SWARM è la spina dorsale del portfolio** e Halo deve
> appartenere a quella famiglia. Recommendation in fondo: **hybrid
> swarm-halo** — Halo eredita la grammatica SWARM e introduce una variante
> consumer (più calda, più editoriale, meno operator-grade).

## Vincoli di partenza (non negoziabili)

- Halo è dark-first per scelta strategica (PDF strategy: "Milan-tech, dark-
  first, premium").
- Halo è anti-performance, anti-AI come messaggio — quindi anti-decoro,
  anti-saturazione, anti-gimmick come tono visivo.
- Halo eredita da SWARM perché è il design language del portfolio: stessa
  famiglia visiva = riconoscibilità cross-prodotto.
- Halo è bilingua IT/EN, quindi il sistema tipografico deve reggere
  entrambe le lingue senza ombre.
- Halo è consumer-social, non operator-tactical. La superficie SWARM
  (frame brand-book, telemetria, RING-A · OP · RING-B) è troppo militare
  per un'app di studenti. Va consumerizzata.

## Tre direzioni a confronto

Per ciascuna: identità, palette, tipografia, motion, tre schermi descritti
abbastanza in dettaglio da poter essere disegnati, e un voto su 5 assi.

---

# Direzione A — Saint Laurent / editorial

**Identità in una frase**: notte calda, italiano premium, italica grave —
come una rivista nel buio.

Direzione vicina all'attuale codice (`HaloTheme.swift`,
`HaloTypography.swift`). Cream/bronze su warm-black. Editorial italic
serif come voce primaria.

## Palette

```
absolute-black       #000000   raro, solo per glow boundary
warm-black           #0F0E10   background principale
night-surface        #161516   surface card
night-surface-2      #1B191A   surface modale / sheet
night-edge           #07070A   linea di separazione

paper-cream          #E4DDCF   testo primario (94% alpha effettivo)
cream-low            E4DDCF @ 0.62  testo secondario
cream-mute           E4DDCF @ 0.42  caption
cream-hair           E4DDCF @ 0.18  hairline
cream-whisper        E4DDCF @ 0.06  whisper

bronze               #A88260   accent attivo (single-use)
bronze-soft          A88260 @ 0.55
bronze-glow          A88260 @ 0.35
```

## Tipografia

| Ruolo | Famiglia | Stile | Esempio |
|---|---|---|---|
| Display / nome persona | Cormorant Garamond | italic 500 | *Giacomo* |
| Headline manifesto | Cormorant Garamond | italic 400 | *le tue persone.* |
| UI / body | Inter (o Satoshi) | regular 400 | "manda la vibe" |
| Eyebrow / micro | IBM Plex Mono | medium 500, tracking 0.18em | INNER · 04 |
| Telemetria | IBM Plex Mono | regular 400 | 12:42 · 4/5 |

Type scale (parziale, allineata a SWARM ma rifinita): 72 · 40 · 28 · 17 ·
15 · 13 · 11. Hero 144 in SWARM è troppo invasivo per Halo consumer — lo
abbassiamo a 72-96 max.

## Motion

Easing `cubic-bezier(0.2, 0.7, 0.1, 1)` (eredita SWARM). Durations:

- Tap → feedback: 120ms
- Card mount: 320ms con stagger 40ms tra card
- Vibe pulse: 4000ms breath (eredita SWARM)
- Sheet present: 420ms

## Schermi (descrizione testuale)

**Orbit Home**

```
┌──────────────────────────────────────┐
│ INNER · 04        12:42 · oggi       │  ← eyebrow mono in cream-mute
│                                      │
│                                      │
│          ◯ Lune                      │  ← inner ring, bolle 96px
│      ◯ Francesca                     │     contorno bronze quando vibe attiva
│   ◯ Giacomo                          │     ritratto su cream-whisper
│       (tu)  Cormorant italic         │  ← self center: nome italic 28pt
│   ◯ Matteo                           │
│      ◯ Chiara                        │
│                                      │
│  · · ◯ Alessia · · close · ·         │  ← close ring, 72px, bronze-soft
│   · ◯ Lorenzo · · ◯ Benedetta · ·    │
│                                      │
│ . . · orbita · . . . . . . .         │  ← orbit ring 52px, cream-hair
│                                      │
│                                      │
│ persone   pulse   compose   profilo  │  ← bottom bar mono in cream-mute
└──────────────────────────────────────┘
```

Nota: nessun bottone "principale" colorato. Le bolle hanno glow bronze solo
quando la vibe è attiva. Tutto il resto è cream su warm-black. L'occhio si
posa sull'italic del nome al centro.

**Compose Moment (vibe-first)**

```
┌──────────────────────────────────────┐
│ ← chiudi                             │
│                                      │
│           come ti senti.             │  ← Cormorant italic 40pt
│                                      │
│  ◯ wild   ◯ chill   ◯ focused        │  ← chip mood, ring bronze quando
│  ◯ warm   ◯ blue    ◯ electric       │     selezionato, glow morbido
│  ◯ lost   ◯ soft                     │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ una nota.                      │  │  ← input field, cream-whisper bg
│  │ ...                            │  │     placeholder cream-mute italic
│  └────────────────────────────────┘  │
│                                      │
│  60 caratteri rimasti                │  ← IBM Plex Mono, tracking, mute
│                                      │
│  Inner · i tuoi 4                    │  ← tier chip, attivo bronze contorno
│  Close · Inner + 12                  │
│  Orbita · Inner + Close + 28         │
│                                      │
│                  manda la vibe       │  ← bottom action, cream su bronze
└──────────────────────────────────────┘
```

**Moment Card (Pulse feed)**

```
┌──────────────────────────────────────┐
│  ◯◯◯  Giacomo                       │  ← portrait 56px con glow vibe color
│        inner · adesso                │     eyebrow mono "inner · adesso"
│                                      │
│       *in loggia, vieni?*            │  ← Cormorant italic 22pt, nota vibe
│                                      │
│  [foto del momento, ratio 4:5]       │  ← optional, no decoration, no border
│  cream-hair come ombra interna       │
│                                      │
│  · · · · · · · · · · · · · · · · · · │  ← decay ring (tratteggio mono)
│  72h  ──◐──────────────              │     che si svuota
│                                      │
│  ✦ pulse · ✦ glow · ⌖ echo           │  ← reazioni stroke 1.5px, cream
│                                      │
└──────────────────────────────────────┘
```

## HALO fit assessment (0-5)

| Asse | Voto | Note |
|---|---|---|
| Premium signal | 4.5 | Editorial italic è il top del segnale premium |
| Anti-cringe | 4.5 | Restraint italiano, niente decorativo |
| Anti-AI positioning | 3.5 | Italic editorial = "scritto a mano da umano" |
| Dark-first | 4 | Warm-black, non absolute black — meno tactical |
| Italian Gen Z resonance | 5 | Cormorant + Milan-night è esattamente il target |
| **Famiglia SWARM** | **2.5** | Diverge dal monochromatic platinum di SWARM |

Forza: è la direzione che parla meglio al Bocconiano italiano. Debolezza: è
**la più lontana dal portfolio SWARM**. Se Halo dovesse stare in una
keynote insieme a un altro prodotto SWARM, sembrerebbe la sorella diversa.

---

# Direzione B — SWARM / operator (PDF allegato as-is)

**Identità in una frase**: superficie operatore in sala controllo —
absolute black, platinum hairline, attivazione in tre colori clinici.

Direzione del documento allegato. Aderenza massima al brand-book SWARM.

## Palette

```
absolute-black       #000000   background
ink-01 → ink-14      gradiente 14 step verso platinum
platinum             #E8E8EA   testo / linee primarie

orbital-blue (lime)  #B8FF00   activation 1 — connected
signal-green (purple)#7B2BFF   activation 2 — operational
launch-amber (mag.)  #FF2BB8   activation 3 — attention
```

## Tipografia

| Ruolo | Famiglia | Stile |
|---|---|---|
| Hero | Cormorant Garamond | italic 400 |
| Display | Satoshi | medium 500 |
| Body | Satoshi | regular 400 |
| Telemetria / mono | IBM Plex Mono | regular 400 |
| Eyebrow | Space Grotesk | medium 500, tracking 0.20em, uppercase |

Type scale SWARM: Hero 144 / H1 64 / H2 40 / H3 28 / Lede 17 / Body 15 /
UI 13 / Eyebrow 11.

## Motion

Easing `cubic-bezier(0.2, 0.7, 0.1, 1)`. Loader 900ms. Breath 4000ms.
"Brightness on hover" come da brand book.

## Schermi

**Orbit Home (SWARM literal)**

```
┌──────────────────────────────────────┐
│ HALO · BOCCONI · 12:42:08            │  ← Space Grotesk uppercase
│ RING-A · OP · RING-B · ATT · RING-C  │  ← telemetry strip
│                                      │
│                                      │
│       · ○ Lune · platinum            │  ← ring-A, contorno platinum 1.5px
│   · ○ Francesca · lime glow          │     vibe attiva = lime halo
│  · ○ Giacomo · purple glow           │
│        DAVIDE  ← Satoshi uppercase   │  ← self center: nome maiuscolo
│  · ○ Matteo · platinum               │
│   · ○ Chiara · magenta glow          │     attention = magenta
│                                      │
│ . . ○ Alessia . . RING-B . . .       │  ← ring-B più sottile
│  . ○ Lorenzo . . ○ Benedetta . . .   │
│                                      │
│ . . . RING-C . . . . . . . .         │
│                                      │
│ FLEET  PULSE  COMPOSE  PROFILE       │  ← Space Grotesk tracked
└──────────────────────────────────────┘
```

**Compose Moment**

```
┌──────────────────────────────────────┐
│ ← CANCEL                             │
│                                      │
│ MOOD · SELECT ONE                    │  ← eyebrow Space Grotesk
│                                      │
│  ○ WILD    ○ CHILL    ○ FOCUSED      │  ← chip stroke-only 1.5px
│  ○ WARM    ○ BLUE     ○ ELECTRIC     │     selected = lime fill
│  ○ LOST    ○ SOFT                    │
│                                      │
│  ────────────────────────────────    │
│  > note                              │  ← IBM Plex Mono cursor
│  ────────────────────────────────    │
│  REMAINING 60                        │
│                                      │
│  VISIBILITY                          │
│  [ RING-A · INNER · 04 ]   ← selected, lime accent
│  [ RING-B · CLOSE · 12 ]                                  │
│  [ RING-C · ORBIT · 28 ]                                  │
│                                      │
│         [ SEND ]                     │  ← uppercase tactical
└──────────────────────────────────────┘
```

**Moment Card (Pulse feed)**

```
┌──────────────────────────────────────┐
│ ○ GIACOMO · RING-A · 12:42           │  ← Space Grotesk tracked
│                                      │
│ in loggia, vieni?                    │  ← Satoshi regular
│                                      │
│ [foto]                               │
│ ─────────────────  72h               │  ← timeline bar tactical
│  PULSE · GLOW · ECHO                 │  ← uppercase reactions
└──────────────────────────────────────┘
```

## HALO fit assessment (0-5)

| Asse | Voto | Note |
|---|---|---|
| Premium signal | 4 | Sharp ma rischia industrial-cold |
| Anti-cringe | 4.5 | Niente è più anti-cringe del SWARM voice |
| Anti-AI positioning | 4 | Operator-grade legge come "fatto da umani esperti" |
| Dark-first | 5 | Absolute black, contrast maximal |
| Italian Gen Z resonance | 2.5 | Operator vocabulary è alienante per non-tech |
| **Famiglia SWARM** | **5** | È SWARM letterale |

Forza: zero ambiguità su appartenenza famiglia. Debolezza: parla operator,
non parla studente. Lime + purple + magenta tutti e tre vivi su una bolla
social sono **troppo** — sembra Telegram aviation app, non gente che si
manda vibe. RING-A/RING-B/RING-C come label utente è inadatto.

---

# Direzione C — Arc / Linear / Cluely minimal

**Identità in una frase**: silenzio assoluto, monocromo puro, un solo
accento elettrico — ridotto a essenza.

Stripping totale. Niente serif, niente decoro, una sola lente di colore.

## Palette

```
black                #0A0A0A
near-black           #111111
platinum             #FFFFFF (al 92%)
hairline             #FFFFFF @ 0.10
mute                 #FFFFFF @ 0.55

accent (single)      #5BFF8A o #B8FF00 (acid lime, una sola scelta)
```

Niente bronze, niente warm. Niente three-activation come SWARM.

## Tipografia

| Ruolo | Famiglia |
|---|---|
| Tutto | Inter (o Geist) variable |
| Mono | IBM Plex Mono |

Una sola famiglia sans, una sola famiglia mono. Niente serif. Niente
italics. Pesi: 400 / 500 / 600.

Type scale: 56 / 36 / 24 / 17 / 14 / 12 / 11.

## Motion

Iper-rapido: 80ms tap, 200ms transition, niente breath. Disegno funzionale,
zero ambient animation.

## Schermi

**Orbit Home**

```
┌──────────────────────────────────────┐
│ inner · 04                    12:42  │
│                                      │
│                                      │
│         ○         ○                  │  ← bolle bianche su nero
│      ○                                │     niente glow, niente colore
│            tu                         │     centro è solo "tu" sans 18
│       ○                               │
│          ○                            │
│                                      │
│ . close . . . . . . . . . . .         │  ← anelli tratteggiati
│ . . . . . . . . . . . . . . .         │
│                                      │
│  inner  pulse  compose  profilo      │
└──────────────────────────────────────┘
```

**Compose Moment**

```
┌──────────────────────────────────────┐
│ ←                                    │
│                                      │
│ come ti senti                        │  ← Inter 24
│                                      │
│  wild  chill  focused                │  ← chip text-only, sottolineato
│  warm  blue  electric                │     quando selezionato
│  lost  soft                          │
│                                      │
│ una nota                             │
│  ____________________________        │
│                                      │
│ 60                                   │
│                                      │
│ inner       close       orbita       │  ← tab semplici, accent sotto inner
│ ─────                                │
│                                      │
│                          manda →     │
└──────────────────────────────────────┘
```

**Moment Card**

```
┌──────────────────────────────────────┐
│ Giacomo · inner · 12 min             │
│                                      │
│ in loggia, vieni?                    │
│                                      │
│ [foto, no border]                    │
│                                      │
│ 72h                                  │
│ pulse glow echo                      │
└──────────────────────────────────────┘
```

## HALO fit assessment (0-5)

| Asse | Voto | Note |
|---|---|---|
| Premium signal | 4.5 | Linear/Arc-tier di restraint |
| Anti-cringe | 5 | Niente da temere visivamente |
| Anti-AI positioning | 2 | Stile *adottato* da molte AI app (Cluely, Granola) |
| Dark-first | 5 | |
| Italian Gen Z resonance | 3 | Funziona per il sub-target tech, debole per fashion-Bocconi |
| **Famiglia SWARM** | **3** | Eredita la sobrietà ma perde palette e type families |

Forza: il design più "scalabile". Debolezza: è quello che assomiglia di più
a 200 altre app. Se Halo è quello che vuole essere ("real, premium, Italian
Milan-night"), C lo rende anonimo.

---

# Recommendation — Hybrid "swarm-halo"

Nessuna delle tre vince da sola. La giocata corretta è una **estensione
SWARM consumer** che eredita la grammatica del design system e introduce
un layer editoriale italiano.

## La formula

```
swarm-halo = SWARM grammar
           + Cormorant editorial soul (da A)
           + bronze warmth invece di lime (da A)
           + 1 sola activation invece di 3 (da C)
           - operator HUD / RING-A labels (toglie da B)
           - all-uppercase taglio (toglie da B)
```

## Cosa si eredita letterale da SWARM (non discutibile)

1. **Sistema spacing** 4/8 fino a 128.
2. **Radii** 6 / 4 / 2 / 999.
3. **Motion easing** `cubic-bezier(0.2, 0.7, 0.1, 1)`.
4. **Iconografia** 24×24 grid · stroke-only 1.5px · round caps · platinum
   at rest.
5. **Voice rules** sentence case · periodi come armi · numerali in cifre ·
   em-dash per pivot · UPPERCASE solo nel wordmark.
6. **Type families** sono le 4 di SWARM: Cormorant Garamond, Satoshi/Inter,
   IBM Plex Mono, Space Grotesk.
7. **Type scale** (con cap a 72 per Hero su mobile, non 144).
8. **Token naming convention** (palette · activation · ink · surface · stroke).

## Cosa Halo customizza dentro la famiglia SWARM

1. **Palette consumer**: una variante warm della palette mono SWARM.
   `absolute-black` → `warm-black #0F0E10`. `platinum` → `paper-cream
   #E4DDCF`. Resta monocromatica ma calda, non clinica. Distingue Halo da
   un altro prodotto SWARM senza romperne la famiglia.
2. **Single activation**: invece dei 3 colori SWARM (lime · purple ·
   magenta) Halo ha **un solo accent attivo: bronze #A88260** + una
   variante "attention" magenta `#FF2B6E` per stati di urgenza
   (downgrade, report, error). Niente lime, niente purple in UI utente.
   Lime/purple/magenta possono restare nel design book come riserva per
   futuri prodotti SWARM o per Halo Events (categoria diversa).
3. **Mood palette OKLCH** per le vibes (già implementata in
   `MoodPalette.swift`): è la lente di colore di Halo, vive su un canale
   diverso (mood, non state). Le bolle prendono il colore mood; le UI
   prendono solo bronze come accent. I due canali non collidono.
4. **Editorial soul**: Cormorant Garamond italic è l'**hero typography**
   di Halo (nomi persone, manifesto headlines, vibe note). In SWARM è una
   delle quattro famiglie, qui diventa la voce principale. Questo è ciò
   che rende Halo riconoscibile come *prodotto Halo* dentro SWARM family.
5. **No HUD labels**: niente "RING-A · OP · RING-B". Halo usa "inner",
   "close", "orbita" in sentence case. La logica SWARM (stati telemetria)
   esiste solo come substrato tecnico, non come copy visibile.
6. **Surfaces live**: SWARM brand-book mostra frame statici. Halo ha
   superfici vive (bolle pulsanti, glow decay, ring breathe). Aggiungiamo
   al design book SWARM una sezione `swarm-halo: living surfaces` che
   formalizza queste estensioni motion.

## Mockup hybrid (Orbit Home)

```
┌──────────────────────────────────────┐
│ inner · 04           12:42 oggi      │  ← IBM Plex Mono micro
│                                      │     paper-cream-mute (62%)
│                                      │
│           ◯ Lune                     │  ← bolla 96px
│      ◯  *Francesca*                  │     ritratto + Cormorant italic
│   ◯  *Giacomo*  bronze glow          │     bronze halo se vibe attiva
│                                      │
│            *davide*                  │  ← centro: Cormorant italic 28
│        IL TUO INNER · 04             │     eyebrow Space Grotesk 9
│                                      │
│   ◯  *Matteo*                        │
│      ◯  *Chiara*  mood-pink halo     │     halo = OKLCH mood color
│                                      │
│   ·  ·  ◯ close  ·  ·  ·             │  ← ring 72px, cream-hair stroke
│  · ◯ Alessia · · ◯ Lorenzo · ·       │
│                                      │
│ . . . . . orbita . . . . . . .       │
│ . . . . . . . . . . . . . . .         │
│                                      │
│ inner   pulse   compose   profilo    │  ← IBM Plex Mono, paper-cream-mute
└──────────────────────────────────────┘
```

Differenze dai 3 stili sopra:

- **Italic Cormorant** sui nomi (eredita A) → marca il prodotto.
- **Single bronze accent** per vibe attiva (eredita A) → niente three-color
  HUD (vs B).
- **Mood color OKLCH** sulle bolle attive → un canale di colore in più
  rispetto a B e C, ma è dato dagli utenti, non dal sistema.
- **Eyebrow Space Grotesk** "il tuo inner · 04" (eredita SWARM grammar).
- **Sentence case + middle dot** (eredita SWARM voice, evita uppercase
  brutalismo di B).

## HALO fit assessment swarm-halo (0-5)

| Asse | Voto |
|---|---|
| Premium signal | 5 |
| Anti-cringe | 5 |
| Anti-AI positioning | 4.5 |
| Dark-first | 4.5 (warm dark, non absolute) |
| Italian Gen Z resonance | 5 |
| **Famiglia SWARM** | **4.5** (eredita grammar, customizza palette/voice in modo legittimo) |

## Pro / contro hybrid swarm-halo

**Pro**:

- Resta riconoscibile come prodotto SWARM senza essere identico al brand
  book (consumerization legittima, non rottura).
- Parla la lingua del target Bocconi senza compromessi.
- Single activation = anti-cringe massimo (niente saturazione).
- Editorial typography come hero = differenziatore vs ogni altra app del
  competitive audit.

**Contro**:

- Servono 4 famiglie font (Cormorant + Satoshi + IBM Plex Mono + Space
  Grotesk) → ~1-2 MB di binario in più. Già accettato in fase precedente
  (bundle in `HaloApp/Resources/Fonts/`).
- Il design system Halo deve essere documentato come **estensione SWARM**,
  non come prodotto a sé. Significa che `docs/design-system/v1.html` di
  SWARM dovrebbe avere un addendum `swarm-halo-v1.md` (o `v1-consumer.md`).
- Bronze come single accent funziona per tutto tranne stati "attention" —
  dobbiamo aggiungere il warm-magenta come secondo accent strettamente per
  errori / downgrade alerts. Non è un rosso (troppo allarme), è
  `#FF2B6E`.

---

## Token preliminari (swarm-halo v0)

```swift
// HaloApp/DesignSystem/Tokens.swift (proposta)

enum SwarmHaloTokens {
  // — Surfaces — ereditate da SWARM con warm shift
  static let absoluteBlack   = Color(hex: "#000000")
  static let warmBlack       = Color(hex: "#0F0E10")  // background
  static let nightSurface    = Color(hex: "#161516")  // card
  static let nightSurface2   = Color(hex: "#1B191A")  // modal sheet
  static let nightEdge       = Color(hex: "#07070A")  // separator

  // — Ink — paper-cream invece di platinum
  static let paperCream      = Color(hex: "#E4DDCF")
  static let creamLow        = paperCream.opacity(0.62)
  static let creamMute       = paperCream.opacity(0.42)
  static let creamHair       = paperCream.opacity(0.18)
  static let creamLine       = paperCream.opacity(0.10)
  static let creamWhisper    = paperCream.opacity(0.06)

  // — Single activation — bronze (vs SWARM lime/purple/magenta)
  static let bronze          = Color(hex: "#A88260")
  static let bronzeSoft      = bronze.opacity(0.55)
  static let bronzeGlow      = bronze.opacity(0.35)

  // — Attention — secondo accent solo per errori/downgrade
  static let warmMagenta     = Color(hex: "#FF2B6E")

  // — Strokes & rings — eredita SWARM
  static let strokeRest      = paperCream.opacity(0.12)
  static let strokeActive    = paperCream.opacity(0.42)

  // — Radii — SWARM literal
  static let radiusCard:   CGFloat = 6
  static let radiusInput:  CGFloat = 4
  static let radiusChip:   CGFloat = 2
  static let radiusPill:   CGFloat = 999

  // — Spacing 4/8 — SWARM literal
  static let s1:  CGFloat = 4
  static let s2:  CGFloat = 8
  static let s3:  CGFloat = 12
  static let s4:  CGFloat = 16
  static let s6:  CGFloat = 24
  static let s8:  CGFloat = 32
  static let s12: CGFloat = 48
  static let s16: CGFloat = 64
  static let s24: CGFloat = 96
  static let s32: CGFloat = 128

  // — Motion — SWARM literal easing
  static let easeSwarm = UnitCurve.bezier(.init(x: 0.2, y: 0.7),
                                          .init(x: 0.1, y: 1))
  static let breath:    Double = 4.0   // seconds
  static let loader:    Double = 0.9
  static let tap:       Double = 0.12
  static let cardMount: Double = 0.32
  static let stagger:   Double = 0.04
}
```

(Non commit-tato ora. Solo proposta di shape.)

---

## Decisione che serve da te

Conferma se la **direzione hybrid swarm-halo** è quella su cui costruire,
oppure se vuoi spingere più verso B (SWARM literal, più operator) o A
(editorial più caldo, più distante dalla famiglia SWARM).

Una volta confermata la direzione, l'output successivo è:

1. `docs/design-system/swarm-halo-v1.md` — il brief versionato nel repo
   come addendum a SWARM.
2. `HaloApp/DesignSystem/Tokens.swift` + sostituzione `HaloTheme` →
   `SwarmHalo`.
3. Bundle font in `HaloApp/Resources/Fonts/` (Cormorant Garamond + Inter +
   IBM Plex Mono + Space Grotesk).
4. Refactor componenti chiave a usare nuovi token.
5. Sweep voce + lessico (file separato `vocabulary.md` già pronto).
