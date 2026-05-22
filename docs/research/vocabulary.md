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

## 5 · Ring / Cerchia / Evento

Il PDF usa **Ring** trasversalmente: Event Ring, Club Ring, Founder Ring,
Course Ring.

Italiano:

- **Ring** — EN, suona come anello / pugilato. Forzato.
- **Cerchia** — corretto ma rischio collisione con "Inner / Close / cerchia
  intima".
- **Stanza** — femminile, suggerisce intimità ma è statico, non temporale.
- **Evento / Club** — il sostantivo concreto, non il container.

**Raccomandazione**:

- **Founder Ring** → resta inglese (è il nome di un'iniziativa di lancio)
- **Event Ring** → in UI diventa solo **"Evento"** (`Event Ring di BIEF
  Welcome` → `BIEF Welcome`). La parola "ring" appare come sottotitolo
  tecnico solo in admin/info: "questo evento è una ring temporanea".
- **Club Ring** → in UI diventa **"Club"**. Stessa logica.
- **Course Ring** → **"Corso"**.

Internamente al codice (modello dati, API) i nomi restano in inglese:
`rings`, `ring_members`, `ring_type`. L'utente non vede mai "ring".

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

## 7 · Inner Invite — "Davide put you in his Inner"

Questo è il loop virale più importante. Deve essere forte ma non transazionale,
emotivo ma non creepy.

Candidati push notification e schermata di accettazione:

- **A.** Davide ti ha messo nel suo Inner.
- **B.** Davide ti ha incluso nel suo cerchio.
- **C.** Sei nell'Inner di Davide.
- **D.** Davide ha scelto te. Inner.
- **E.** Davide ti chiede vicino.

**Raccomandazione**:

- Push notification: **C** ("Sei nell'Inner di Davide.") — passiva,
  inequivocabile, sentence case, periodo.
- Accept screen headline: **A** ("Davide ti ha messo nel suo Inner.")
- Sottotitolo: "Inner è limitato a 5 persone. È un segnale."

Mai usare punti esclamativi. Mai "congratulazioni". Mai "felicitazioni".
Mai "wow". Tono SWARM: piatto, fermo, premium.

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

## Sintesi: 5 decisioni che servono adesso

1. **Inner / Close** restano in inglese in tutta la UI. Orbita / Nebula in
   italiano. Il `FriendshipTier.label` cambia.
2. **Manifesto headline** italiana = "Le tue persone. Non un pubblico."
3. **Moment** in inglese come termine di feature. **Frammento** per Memory.
4. **Ring** non appare mai in UI utente. Diventa **Evento / Club / Corso**.
5. **Voice rules SWARM** si applicano in italiano: sentence case, periodi,
   mai esclamativi, mai "tu/voi/noi/Lei", numerali in cifre.

Se confermi questi cinque punti, il code-sweep di lessico è ~1 ora di lavoro
e va in commit separato prima della Fase A design.
