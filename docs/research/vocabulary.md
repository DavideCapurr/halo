# Halo — vocabolario e copy

> Stress test del lessico in italiano. Output: una riga di raccomandazione per
> termine, più la lista dei file Swift da aggiornare. Niente sweep di codice
> in questo round — solo decisioni.

## Principio di partenza

Halo non è un'app italiana, è un'app **bilingue per studenti Bocconi**: metà
italiani, metà internazionali. Il registro vincente non è "italiano puro" né
"english only", è **italiano premium con anglicismi precisi** — esattamente
come parlano i Bocconiani in corridoio e come scrivono i brand di moda
italiani che vogliono parlare al mondo (Marni, Sunnei, Slowear, GCDS).

Regola operativa: **i termini di prodotto restano in inglese quando sono
sacri e brand-specific**. Tutto il resto in italiano sentence case.

Il file modello (`FriendshipTier.swift`) oggi traduce tutto:

```swift
public var label: String {
  case .inner:  return "Cerchio"
  case .close:  return "Vicini"
  case .orbit:  return "Orbita"
  case .nebula: return "Nebula"
}
```

La raccomandazione è di rivedere questa scelta su due termini.

---

## 1 · Manifesto headline

"Your people, not your audience."

Candidati italiani:

- **A.** Le tue persone. Non un pubblico.
- **B.** Persone vere. Non un pubblico.
- **C.** La tua gente, non il tuo pubblico. *(più caldo, meno sharp)*
- **D.** I tuoi. Non il pubblico. *(troppo ellittico)*
- **E.** Your people, not your audience. *(EN, come Lapo / Lapo Elkann fa
  spesso nei suoi brand)*

**Raccomandazione: A** sulla welcome italiana. **E** sul touchpoint globale
(landing web) e nella prima schermata se vogliamo segnalare "questo prodotto
è internazionale, non comunale". *A* tiene la struttura SWARM: due frasi,
periodi come armi, niente virgola che ammorbidisce.

Versione lunga sotto al manifesto: "Organizza chi è vicino. Condividi solo
fin dove un momento deve arrivare."

---

## 2 · Tier names — Inner / Close / Orbit / Nebula

| EN | IT attuale | IT alternativi | Raccomandazione |
|---|---|---|---|
| Inner | Cerchio | Cerchia, Nucleo, I tuoi 5 | **Inner** in copy chiave, *cerchia* in UI esplicativa |
| Close | Vicini | Cerchia, Vicinanza, I tuoi 15 | **Close**, *vicinanza* in copy lungo |
| Orbit | Orbita | (resta) | **Orbita** |
| Nebula | Nebula | (resta) | **Nebula** |

Argomenti:

- **"Cerchio"** è il termine generico per qualunque cerchia (cerchio di amici,
  cerchio aziendale). Non porta peso emotivo. **"Inner"** invece è una parola
  intima e specifica — gli utenti la imparano una volta e diventa
  brand-specific (come "Stories" per Instagram). In Bocconi, dire "ti ho
  messo nel mio Inner" suona più reale che "ti ho messo nel mio cerchio".
- **"Vicini"** in italiano evoca il condominio. "Close" mantiene il senso di
  vicinanza emotiva senza l'ambiguità geografica. *Cerchia* (femminile) è il
  fallback più premium se vogliamo restare in italiano, ma rompe la
  simmetria EN-IT.
- **"Orbita"** e **"Nebula"** sono internazionali, restano identici, sono già
  i termini meno controversi.

Conseguenza per il codice: `FriendshipTier.label` dovrebbe diventare
`"Inner"`, `"Close"`, `"Orbita"`, `"Nebula"`. La versione "spiegata" (per
help text, accessibility) può restare in italiano: "i tuoi 5", "i tuoi 15",
"la tua orbita", "tutti gli altri".

---

## 3 · Vibe vs Presenza

PDF dice **Vibe**. Codebase usa entrambi:

- `SignInView.swift:26` → "presenza, non performance"
- `VibeSetterView.swift:28` → "La tua vibe"
- `TopBarView.swift:18` → "la tua vibe · {mood}"

**Vibe** ha vinto a livello culturale: in italiano Gen Z si dice "che vibe
ha", "una vibe strana", "vibe boccon". Non è un anglicismo forzato, è
naturalizzato. Il PDF strategy lo conferma e i seed in `SeedPeople.swift`
sono già scritti come note vibe ("in loggia, vieni?", "navigli tra un'ora").

**Presenza** ha valore in copy filosofico, non operativo. Sta bene nel
manifesto ("presenza, non performance") ma non nei controlli.

**Raccomandazione**: **Vibe** è il nome del controllo. **Presenza** resta
solo come parola del manifesto. Niente "imposta la presenza" — è
**"imposta la vibe"** o **"manda la vibe"** (già in `VibeSetterView`).

---

## 4 · Moment / Momento / Segnale

"Momento" in italiano è debole — comune, intercambiabile con "attimo",
nessuna gravità. "Moment" in inglese è più solido (come "moments that
matter").

Alternativi:

- **Momento** — l'ovvio. Debole.
- **Frammento** — più letterario, evoca raccolta archivistica. Buono per
  Memory.
- **Istante** — più poetico ma rischia precious.
- **Segnale** — operativo, allineato a SWARM (signal/ring/node). Forte.
- **Moment** — EN, brand-stable.

**Raccomandazione**: **Moment** come termine di prodotto (il bottone, la
notifica). **Frammento** come termine per l'archivio Memory ("i tuoi
frammenti del semestre"). In copy lungo Italian-flowing, "momento" può
apparire come parola comune ma non come label di feature.

`HaloSpaceView.swift:194` oggi dice "nessun momento attivo nelle ultime 72h"
— questo va bene come copy descrittiva.

---

## 5 · Halo (sostituisce "Ring")

> **Decisione presa**: la parola **Ring** sparisce da tutta la UI utente.
> Halo diventa il sostantivo user-facing per "cerchio di persone attorno
> a qualcuno o qualcosa".

Il PDF strategy usa **Ring** come primitiva trasversale (Event Ring, Club
Ring, Founder Ring, Course Ring). Spostiamo tutto su **Halo**:

| PDF | Halo (UI utente) | Internal (codice) |
|---|---|---|
| your ring of people | il tuo halo | `user.halo` (insieme tier) |
| inner ring | inner (tier) | `tier = inner` |
| Event Ring | Evento / Event Halo | `rings.type = event` |
| Club Ring | Club / Club Halo | `rings.type = club` |
| Founder Ring | Founder Halo | `rings.type = founder` |
| Course Ring | Corso / Course Halo | `rings.type = course` |

### Conseguenze semantiche

- **Halo = brand + sostantivo del prodotto.** Come "snap" per Snapchat,
  "tweet" per Twitter. È la cosa che possiedi. Forte.
- **Il tuo halo** = la tua mappa di persone (Inner + Close + Orbit + Nebula
  tutti insieme, senza differenziare in pubblico).
- **Nell'halo di Davide** = sei stato ammesso. Tier non rivelato.
  Rispetta il principio PDF "never reveal downgrades — never humiliate by
  exposing tier".
- **Event Halo** = il cerchio temporaneo attorno a un evento. In UI compare
  come "Evento" (sostantivo concreto). "Halo" appare solo se serve
  disambiguare in copy lungo.
- **Glow bronze nel design** = letteralmente il halo della persona. La
  metafora visiva ora porta peso semantico, non è solo decoro.

### Regole d'uso

- Mai dire "ring" nella UI. Mai.
- "Halo" da solo è ambiguo (potrebbe essere brand o sostantivo). Usa
  **possessivo o specificatore**: `il tuo halo`, `l'halo di Davide`,
  `Event Halo`, `nel mio halo`.
- Quando un Event Halo / Club Halo è in lista, mostralo col nome
  concreto ("BIEF Welcome", "Aperitivo Bligny"), non con la parola Halo
  ripetuta.

### Codice

Internamente, il modello dati può tenere `rings`, `ring_members`,
`ring_type` (sono nomi tecnici, non li vede l'utente). Se vuoi
allineamento più stretto si rinomina a `halos`, `halo_members`,
`halo_type` quando arriva il momento della migrazione DB (Fase B). Per
ora propongo di **tenere il nome DB `rings`** e fare il rename solo se
emerge un motivo reale (es. confusione interna nel team).

---

## 6 · Onboarding — "Choose your real 5"

Candidati:

- **A.** Scegli i tuoi cinque.
- **B.** Scegli i tuoi 5.
- **C.** Cinque persone. Quelle vere.
- **D.** Il tuo Inner: cinque persone.
- **E.** Choose your real 5. *(EN)*

**Raccomandazione**: **B** per il titolo della schermata, **C** come
sottotitolo. Numerali in cifre — il PDF lo specifica, SWARM lo specifica,
ed è la regola tipografica di telemetria.

Schermata `InitialInnerCircleView` aggiornata:

```
Inner

scegli i tuoi 5.
le persone con cui vuoi essere reale.
massimo 5 · li puoi spostare quando vuoi
```

---

## 7 · Invite copy — generica e Inner-specifica

Due loop virali, due livelli di calore. La generica protegge da
humiliation; la Inner-specifica conserva lo status signal sacro.

### A. Generica — "Davide added you in his halo"

Per qualunque add che non sia Inner (Close / Orbit). Tier non
rivelato in copy esterna.

Candidati:

- **A1.** Davide ti ha aggiunto al suo halo.
- **A2.** Sei nell'halo di Davide.
- **A3.** Davide ti ha incluso.
- **A4.** Davide ti vede.

**Raccomandazione**:

- Push notification: **A2** ("Sei nell'halo di Davide.") — passiva,
  inequivocabile, niente verbo che possa sembrare azione gerarchica.
- Accept screen headline: **A1** ("Davide ti ha aggiunto al suo halo.")
- Sottotitolo: "Vedrai la sua presenza. Aggiungi Davide al tuo halo
  quando vuoi."

### B. Inner Invite — "Davide put you in his Inner"

Solo quando il tier assegnato è `inner`. Questo è il loop virale
sacro del PDF, status signal massimo. La parola **Inner** appare
esplicita perché è il punto.

Candidati:

- **B1.** Sei nell'Inner di Davide.
- **B2.** Davide ti ha messo nel suo Inner.
- **B3.** Davide. Inner.
- **B4.** Inner: Davide ti ha scelto.

**Raccomandazione**:

- Push notification: **B1** ("Sei nell'Inner di Davide.") — sentence case,
  periodo, mai esclamativo.
- Accept screen headline: **B2** ("Davide ti ha messo nel suo Inner.")
- Sottotitolo: "Inner è limitato a 5 persone. È un segnale."

### Regola di sistema

Mai esclamativi. Mai "congratulazioni". Mai "felicitazioni". Mai "wow".
Mai "🎉". Tono SWARM: piatto, fermo, premium. La gravità della cosa la
porta il fatto che è successo, non il punto esclamativo.

---

## 8 · Vibe presets in italiano

Lista PDF + traduzione:

| EN | IT raccomandato | Alternativi scartati |
|---|---|---|
| locked in | **in studio** | "concentrato", "focus" (troppo da app produttività) |
| lowkey | **lowkey** | "tranquillo" (perde il tono), "tranqui" (cringe) |
| out tonight | **fuori stasera** | "uscita", "in giro" |
| studying | **biblio** *(Bocconi)* / **studio** | "studiando" |
| stressed | **sotto pressione** | "stressato" (debole), "stress" |
| open to plans | **aperto** | "disponibile" (formale), "libero" |
| recovering | **recupero** | "in recupero" (verboso) |
| offline | **offline** | (resta) |
| do not disturb | **non disturbare** | "occupato", "DND" |

Note:

- **biblio** è gergo Bocconi → ottimo cold-start signal (segnala "questa app
  parla la mia lingua"). Vale forse anche `loggia`, `aula 4`, `aula 7`
  come preset evoluti / Halo+.
- **lowkey** stays EN: è già una vibe parola in italiano Gen Z.
- I preset sono frasi non-azione (non "studiando" → "in studio"). Lo stato,
  non il verbo.

---

## 9 · Voice rules SWARM → adattamento italiano

SWARM rules (spread 21 del design book):

- Sentence case.
- Periods are weapons.
- Mai esclamativi.
- Third person · imperative. Rarely "we". Almost never "you".
- Numerali sempre in cifre.

Adattamento italiano:

- **Sentence case** → tiene. È contro-tendenza in italiano (che ama il Title
  Case in pubblicità) ma è il segnale premium che vogliamo.
- **Periodi come armi** → tiene **a costo di un'italiano frammentato**.
  Italian writing flowa con virgole. Halo accetta lo strappo. "Scegli i
  tuoi 5. Le persone vere. Niente pubblico." è più Halo che "Scegli i tuoi
  cinque, le persone vere, niente pubblico".
- **Mai esclamativi** → tiene assoluto. Anche dove un "!" sarebbe naturale
  ("Benvenuto!"). Diventa "Benvenuto."
- **Third person · imperative** → in italiano usiamo l'imperativo
  ("Scegli", "Manda", "Imposta"). Mai "tu". Mai "voi". Mai "Lei". Mai "noi".
  Manda il messaggio dall'app come **istruzione operativa**, non come
  amicone che parla al chat.
- **Em-dash** → ce ne sono pochi in italiano premium. Sostituibili con due
  spazi e un punto, oppure con `·` (middle dot, già usato in copy SWARM e in
  `HomeView.swift` — "Cerchio, vicini, orbita" potrebbe diventare "cerchio
  · vicini · orbita").

---

## 10 · Code audit — file da aggiornare

Stringhe attualmente disallineate dalla raccomandazione:

| File | Riga | Attuale | Verso |
|---|---|---|---|
| `HaloShared/Sources/HaloShared/Models/FriendshipTier.swift` | 27-34 | `"Cerchio"/"Vicini"/"Orbita"/"Nebula"` | `"Inner"/"Close"/"Orbita"/"Nebula"` |
| `HaloApp/Features/Home/HomeView.swift` | 203 | `orbitStatCell("cerchio", ...)` | `orbitStatCell("inner", ...)` |
| `HaloApp/Features/Home/HomeView.swift` | 286-287 | `"CER" / "VIC"` | `"INN" / "CLO"` |
| `HaloApp/Features/Home/ZoomSlider.swift` | 137-139 | `"Solo cerchio" / "Cerchio e vicini" / "Cerchio, vicini, orbita"` | `"solo inner" / "inner · close" / "inner · close · orbita"` (sentence case, middle dot) |
| `HaloApp/Features/Compose/VibeFirstComposeView.swift` | 305-306 | `"i tuoi {n} del cerchio" / "cerchio + i tuoi {n} vicini"` | `"i tuoi {n} di Inner" / "Inner + i tuoi {n} di Close"` |
| `HaloApp/Features/Auth/InitialInnerCircleView.swift` | 53 | `"massimo 5 · li puoi aggiornare in ogni momento"` | `"massimo 5. li puoi spostare quando vuoi."` |
| `HaloApp/Features/Profile/TierConfirmationSheet.swift` | 159-162 | descrizioni capability per tier | sweep sentence case + periodi |
| `HaloApp/Features/HaloSpace/HaloSpaceView.swift` | 191 | `"HaloSpace vuoto"` | `"halospace vuoto."` (sentence case + periodo, OR "halo space silenzioso." se vogliamo poetico) |
| `HaloApp/Features/HaloSpace/HaloSpaceView.swift` | 194 | `"nessun momento attivo nelle ultime 72h"` | tiene, sentence case ok |
| `HaloApp/Features/Auth/SignInView.swift` | 23-26 | `"Halo" + "presenza, non performance"` | tiene + aggiungere headline `"persone vere. non un pubblico."` |

Lo sweep si fa in un commit dedicato dopo che hai approvato le regole sopra,
non in questo round di ricerca.

---

## Sintesi: 6 decisioni — confermate

1. **Inner / Close** restano in inglese in tutta la UI. Orbita / Nebula in
   italiano. Il `FriendshipTier.label` cambia. *(confermato)*
2. **Manifesto headline** italiana = "Le tue persone. Non un pubblico."
3. **Moment** in inglese come termine di feature. **Frammento** per Memory.
4. **Ring → Halo** in tutta la UI utente. Halo è sostantivo del prodotto
   ("il tuo halo", "nell'halo di Davide", "Event Halo"). Internalmente il
   DB può tenere `rings` finché non c'è una ragione operativa per
   rinominare. *(confermato 22 mag)*
5. **Voice rules SWARM** si applicano in italiano: sentence case, periodi,
   mai esclamativi, mai "tu/voi/noi/Lei", numerali in cifre.
6. **Invite copy bipolare**: generica `Sei nell'halo di Davide` per add a
   qualunque tier diverso da Inner (no tier reveal); specifica `Sei
   nell'Inner di Davide` solo quando il tier è Inner (status signal
   sacro). *(confermato 22 mag)*

Il code-sweep di lessico (~1 ora) va in commit separato prima della Fase A
design.
