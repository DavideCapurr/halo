# Halo — direzione visiva

> Documento canonico per lo stile dell'app. Deriva da `docs/PRODOTTO.md`:
> nessuna scelta visiva qui dentro è di gusto, ognuna scende dalla tesi.
>
> Sostituisce `docs/design-system/swarm-v1.md`,
> `docs/design-system/swarm-halo-v1.md` e la raccomandazione finale di
> `docs/research/aesthetic-directions.md`. Quei tre file sono archiviati in
> `docs/archive/` come storia, non come riferimento.

**Halo è un'app che sembra tua, non una rivista.**

---

## 1 · Perché lo stile si deriva, non si sceglie

La tesi di prodotto è: la rete delle persone che hai incontrato davvero, senza
ansia da performance.

Da lì scende un vincolo che decide quasi tutto:

> **Ogni scelta visiva che alza il valore percepito di un post lavora contro
> il prodotto.**

Un'app che sembra preziosa fa venire voglia di postarci dentro qualcosa
all'altezza. È esattamente il costo psicologico che Halo esiste per azzerare.
Non è una questione di gusto: è che "premium ovunque" e "anti-performance"
sono obiettivi incompatibili, e uno dei due deve cedere.

Guarda cosa ha vinto in questa categoria: BeReal usava la fotocamera di
sistema senza filtri, Close Friends è un cerchio verde, Locket è una foto in
un widget. Il basso costo di produzione **è** la feature.

Instagram fa l'opposto — griglia bellissima, posting ad alto costo — ed è
precisamente il motivo per cui le persone sono scappate nelle Close Friends:
un posto brutto dentro un posto bello.

---

## 2 · Perché il design system era fermo

Registrato perché non si ripeta, non per archeologia.

Il repo conteneva **quattro risposte incompatibili** alla stessa domanda:

| Fonte | Diceva | Stato |
|---|---|---|
| `aesthetic-directions.md` | hybrid swarm-halo: warm-black, paper-cream, **un solo accent bronze**, esplicito "niente lime, niente purple in UI utente" | "confermata 22 mag" |
| `PLAN.md` Fase A | SWARM canonico: mono 14 step, absolute-black → platinum, **tre activation** (lime · purple · magenta) | bloccato |
| `swarm-halo-v1.md` | si autodichiarava *legacy* rimandando a swarm-v1.md, ma il proprio diagramma lo chiamava ancora "canonical reference" | si contraddiceva |
| commit recenti | "black glass surfaces", "normalize black glass tokens" | terza strada |

E il codice teneva insieme la contraddizione con dei ponti, invece di
risolverla:

```swift
// Tokens.swift — MARK: Legacy activation aliases
static let orbitalBlue = bronzeAccent
static let signalGreen = bronzeAccentSoft
static let launchAmber = attention
static let warmBlack   = Palette.absoluteBlack
```

I tre activation SWARM erano alias del bronze. Il warm-black era alias
dell'absolute-black.

### La causa

`aesthetic-directions.md` apriva con "vincoli di partenza (non negoziabili)",
e dentro c'era:

> «Halo eredita da SWARM perché è il design language del portfolio: stessa
> famiglia visiva = riconoscibilità cross-prodotto.»

Non si risolve un conflitto in cui una parte è dichiarata non negoziabile ed è
anche quella sbagliata. Tre ragioni per cui era sbagliata:

1. **La riconoscibilità cross-prodotto non esiste ancora.** È un beneficio che
   si realizza solo se qualcuno usa più prodotti del portfolio. Halo ha zero
   utenti: era un costo pagato in anticipo per un vantaggio che potrebbe non
   arrivare mai.
2. **SWARM è un linguaggio operator, Halo è consumer.** Lo ammetteva il
   documento stesso — "troppo militare per un'app di studenti", "va
   consumerizzata". Ogni decisione visiva era una trattativa fra un linguaggio
   che non calza e la cosa che calzerebbe.
3. **Si vedeva nei radii.** 6 / 4 / 2 px sono raggi da strumento tecnico. Un
   posto dove condividi qualcosa di personale non ha bordi a 2px.

### La decisione

**SWARM esce dai vincoli di Halo.** Non perché sia sbagliato: perché
appartiene a un altro prodotto, con un altro utente e un altro lavoro da fare.

Se un giorno il portfolio avrà bisogno di parentela visiva, si costruirà
allora, sopra un prodotto che funziona. Non prima.

---

## 3 · Il principio: guscio premium, atto banale

C'è una tensione reale nel target. Bocconi è status-sensibile: l'esclusività
tira, e un'app che sembra povera non entra in quel mondo. Ma vedi §1.

La risoluzione non è un compromesso al 50%. È una **separazione netta fra due
momenti** dell'esperienza.

### Il guscio — alza le aspettative

Icona, invito, primo avvio, verifica, il momento "sei dentro", wordmark.

Cura massima. Tipografia grande, spazio, ritmo, una frase sola, un bottone
pieno. Succede **una volta** ed è la cosa che l'utente mostra a un amico:
deve valere la pena di essere mostrata.

### L'atto — abbassa le aspettative

Comporre, mandare, reagire, rispondere.

Deliberatamente ordinario. Nessuna cornice preziosa, nessuna griglia da
galleria, nessun serif, scadenza visibile. Succede **ogni giorno**, e ogni
grammo di bellezza aggiunto qui è un grammo di ansia aggiunto al postare.

---

## 4 · Le cinque regole

### R1 — Il guscio è premium, l'atto è banale

Il segnale di status vive nel guscio. L'atto di condividere resta ordinario,
veloce, a basso costo.

> **Test:** se una schermata fa venire voglia di postare *qualcosa
> all'altezza*, quella schermata è progettata male.

### R2 — Dark-first perché è intimo, non perché è premium

La scelta del dark resta. Cambia la ragione, e la ragione determina tutto
quello che ne deriva.

Il dark di Halo è sera, camera, schermata di blocco, voce bassa. Non è
"Milan-tech premium".

> Da *premium* derivi contrasto alto, oro, serif, bordi netti.
> Da *intimo* derivi contrasto morbido, nessun oro, raggi ampi, tipografia
> piana. Stessa scelta, due app completamente diverse.

### R3 — Un font solo

Gerarchia da dimensione, peso e opacità. Mai da famiglia.

Cormorant Garamond italic sui nomi delle persone è bellissimo e sbagliato:
trasforma i tuoi amici nella testata di una rivista — cioè in contenuto da
guardare, invece che in persone a cui rispondere.

> Effetto collaterale: spariscono quattro famiglie di font, ~2 MB di binario e
> il blocco "mancano i file Satoshi ufficiali" che teneva ferma la Fase A.

### R4 — Il colore viene dalle persone, non dal brand

**Halo non ha un accent color.** L'interfaccia è bianca e nera.

L'unico colore dell'app è quello degli stati delle persone: il canale mood
OKLCH già implementato in `MoodPalette.swift`, oggi relegato a canale
secondario. Va invertito — da dettaglio a fondamento.

L'app è grigia quando non c'è nessuno e viva quando ci sono le tue persone.

Tre conseguenze:

- Il colore acquista significato letterale: **colore = qualcuno c'è.**
- La lite bronze-contro-lime finisce senza vincitori, perché il brand smette
  di avere un colore.
- Il *halo* attorno al ritratto diventa davvero ciò che il nome dice.

> È l'unica scelta visiva del documento che è anche un vantaggio competitivo:
> nessun prodotto del competitive audit lo fa. E insegna la tesi del prodotto
> senza una riga di copy — se il tuo Halo è spento, non è colpa dell'app: è
> che non hai ancora incontrato nessuno.

### R5 — Il widget è lo schermo principale

La ritenzione di Halo vive nella schermata di blocco, non nell'app. Il widget
si disegna **per primo**; l'app è la sua estensione, non il contrario.

Zero testo oltre alle iniziali. Nessun conteggio, nessun badge, nessuna
notifica che chiede di essere aperta. Solo il colore delle persone che cambia
durante il giorno.

> Quasi tutte le app fanno l'inverso: costruiscono l'app e attaccano un widget
> alla fine. Ma il loop di Halo — "vedi come stanno i tuoi senza doverci
> parlare" — si compie interamente lì. Se funziona solo aprendo l'app, non hai
> un prodotto di presenza.

---

## 5 · Stato nei token

Applicato al layer token il 6 agosto 2026. La strategia è stata cambiare
**valori mantenendo ogni simbolo**, così le ~24 superfici che consumano i token
hanno ereditato la direzione senza un refactor di massa.

| Elemento | Prima | Ora |
|---|---|---|
| activation | 3 alias SWARM → bronze | neutri e deprecati, nessun accent |
| colore | bronze + mood secondario | solo mood, dalle persone |
| font | 4 famiglie, bloccato su Satoshi | 1 famiglia di sistema |
| radii | 6 / 4 / 2 — operator | 20 / 16 / 12 — morbidi |
| ink | paper-cream `#E4DDCF` | bianco a opacità variabile |
| ground | `= absoluteBlack` (#000) | `#0B0C0E`, freddo appena |
| tier | bronze per inner/close | opacità dell'ink: vicino = più presente |
| widget | lime · purple · magenta SWARM | ink neutro, colore solo dai mood |

Il nero puro resta, ma solo dove serve davvero: ombre, scrim e il vuoto
`farRest`. Non è più uno sfondo.

### Cosa è rimasto deprecato, non rimosso

`bronze`, `bronzeSoft`, `bronzeGlow`, `orbitalBlue`, `signalGreen`,
`launchAmber` esistono ancora e risolvono a neutro. Tenerli evitava di toccare
~20 call site in un colpo solo; vanno migrati a ink o a un mood reale quando si
passa sulle rispettive view.

`attention` (`#FF2B6E`) resta l'unico token colorato che non è una persona: è
**semantico**, non brand — un errore non deve mai essere silenzioso.

### Cosa si è sbloccato

I tre item `[!]` di Fase A hanno perso oggetto: niente palette mono 14 step,
niente file Satoshi ufficiali, niente mapping stati↔SWARM. I `.ttf` in
`HaloApp/Resources/Fonts/` (~2,4 MB) e le voci `UIAppFonts` non sono più
referenziati; rimuoverli tocca il progetto Xcode ed è tracciato in `PLAN.md`.

### Cosa resta buono

`MoodPalette.swift` è l'idea migliore del design system esistente ed è ora il
fondamento. Spacing 4/8, easing `cubic-bezier(0.2, 0.7, 0.1, 1)` e la
disciplina anti-saturazione restano: sono igiene, non identità.

---

## 6 · Come si verifica

Questa direzione è una tesi, non una certezza. Si testa **insieme** alle
conversazioni di prodotto di `docs/PRODOTTO.md` §10, senza costruire nulla:
due schermate statiche, la versione premium-ovunque e la versione
guscio-premium-atto-banale.

Una domanda sola, a dieci persone:

> *«Qui dentro ci posteresti una foto fatta male?»*

- Se sulla schermata premium la risposta è "no, è troppo bella" → la tesi
  regge, ed è la conferma che serve.
- Se sulla versione ordinaria la risposta è "sembra un'app finita a metà" → il
  problema è di esecuzione, non di direzione. **Banale non vuol dire sciatto**,
  e la differenza sta interamente nella precisione di spaziatura, ritmo e
  tocco.

---

## 7 · Come si giudica una scelta visiva

Quattro domande, tutte da superare. Complementari alle cinque di
`docs/PRODOTTO.md` §9.

1. **Alza il costo psicologico di postare?** Se sì, va nel guscio o non va.
2. **Sta nel guscio o nell'atto?** Se non sai rispondere, la schermata non ha
   un ruolo chiaro.
3. **Introduce colore che non viene da una persona?** Se sì, no.
4. **Funziona nel widget?** Se il concetto non sopravvive a 36×36 px senza
   testo, non è centrale quanto pensi.
