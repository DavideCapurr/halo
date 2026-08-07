# La v1 regge?

> Verifica di `docs/V1.md` (deciso il 2026-08-06) contro gli obiettivi di
> `docs/PRODOTTO.md`. Due domande separate: **la v1 serve gli obiettivi**, e
> **l'idea può funzionare**.
>
> Stato del codice verificato file per file il 2026-08-07, non sui documenti.
> Scritto per essere sgradevole dove serve: `docs/VERIFICA-OBIETTIVI.md` lo era
> con `PERIMETRO.md`, e sarebbe inutile essere più gentili col documento che ne
> è uscito.

---

## 0-bis · Cosa è stato deciso dopo questa verifica

*Aggiunto il 2026-08-07, poche ore dopo il resto del documento. Il testo sotto
resta invariato: è il registro del perché, non un documento vivo.*

| Rilievo | Esito |
|---|---|
| §1.3 — la porta su invito e il budget | **Accolto: escono entrambi.** La porta torna a essere l'incontro (scan di persona, link, QR). E5 — inviti aperti con link e codice — resta in onda 1, perché è idraulica, non un gate |
| §1.3d — il conflitto di canone con `PRODOTTO.md` §4 | **Risolto senza lavoro.** Rovesciata la porta, il loop di `PRODOTTO.md` §4 e `FUNZIONI.md` §2 torna a descrivere il prodotto |
| §2 — O2 danneggiato dal budget | **Chiuso.** Senza budget, l'exchange che torna a Madrid non ha un tetto agli ingressi |
| §1.2 — l'ampiezza e il calendario | **Respinto, con motivazione.** Perimetro e data restano; la scommessa dichiarata è la velocità di esecuzione con Claude Code. `V1.md` §2 ora dice cosa quella velocità **non** comprime |
| §3.3 — R1 e R2 fermi | **Aperto.** Resta il rilievo più grave, e la decisione sul calendario lo rende più grave, non meno |

Conseguenza derivata, applicata: **E6 sale dall'onda 2 all'onda 1.** Il gate era
la rete di sicurezza per chi arriva da solo; tolto il gate, quella persona entra
e trova l'app vuota.

Sull'idea in sé, §4.2b (l'invito peggiora la densità) decade con la porta.
**Restano validi e non affrontati gli altri quattro:** la ritenzione non
verificata (a), il moat che difende dal modo di morire sbagliato per la
categoria (c), WhatsApp come incumbent reale (d), la monetizzazione che si vuole
in onda 4 e quella che si rifiuta già costruita (e).

---

## 0 · Verdetto in tre righe

1. Delle tre decisioni della v1, **una è giusta ed è più economica di come è
   scritta** (il centro), **una non è una decisione** (l'ampiezza), **una fa
   danno all'obiettivo che dovrebbe servire** (la porta).
2. **L'onda 1 non è un'onda, è un lancio intero**, e il calendario che la
   misura non è calibrato su nessun ritmo osservato: negli ultimi trenta giorni
   il repo ha prodotto tre documenti e zero righe di prodotto.
3. L'idea **può** funzionare — la tesi è coerente e il cuneo è scelto bene — ma
   poggia su due cose mai verificate: che il problema sia sentito e che la
   presenza trattenga. La v1 risponde a questo rischio **aumentando il
   perimetro**. È la reazione sbagliata al rischio dominante.

---

## 1 · Le tre decisioni, una per una

### 1.1 · Il centro = le persone · **giusta, e già mezza fatta**

È la decisione migliore delle tre, ed è la risposta diretta al rischio Path
identificato in `VERIFICA-OBIETTIVI.md` §3.

Ma la v1 la tratta come lavoro da fare, e in gran parte non lo è.
`HomeView.swift:359` — l'app **apre già** su `orbitTab`, cioè il campo delle
persone con le bolle tinte dal mood, non sul feed. Il feed (`Pulse`) è già una
tab secondaria. La riga "Home = le persone" nell'onda 1 non descrive una
schermata da costruire: descrive una schermata che esiste e che è **vuota**.

È vuota per una ragione sola, ed è un'altra riga della stessa tabella: nessuno
popola `follows`. Quindi:

> "Home = le persone" non è un item. È la conseguenza di E3 (roster). Se E3
> esiste, la home è già giusta; se E3 non esiste, nessuna schermata nuova la
> salva.

### 1.2 · L'ampiezza = tutte e 29 · **non è una decisione**

`V1.md` §1: *"Tutte e 29 le funzioni. Nessun taglio permanente."* Poi §4 le
distribuisce su quattro onde in ~14 settimane.

Distribuire su quattro onde **è** il taglio: quello che sta in onda 4 non
esiste al lancio esattamente come se fosse stato tagliato. La differenza è solo
che nessuno ha dovuto dire di no a niente.

Il costo non è retorico. `docs/launch/FEATURE-LANCIO.md` aveva un criterio
tagliente — *"se questa feature manca, la matricola si ferma o si annoia?"* — e
quel criterio produceva una lista P0 di ~11 item in 3 settimane. `V1.md`
sostituisce quel criterio con un elenco di 15 item in 4 settimane che include
**tutta** la lista precedente più cinque cose nuove (E4, E7, U4, R3a completo,
"home = le persone"). Non è una revisione della priorità: è la stessa lista con
sopra roba in più, e senza più la domanda che l'aveva prodotta.

### 1.3 · La porta = solo su invito · **coerente con la tesi, contraria a O2, inesistente nel codice**

Quattro problemi distinti, in ordine di gravità.

**a) Non esiste, e lo schema fa il contrario.**
`invites.invitee_id` è `not null`
(`supabase/migrations/20260604152121_inner_invites.sql:9`): oggi si può
invitare **solo chi è già iscritto**. Non c'è tabella dei codici, non c'è
budget, non c'è redenzione, non c'è gate in `SignInView`. Nel repo esistono
`founder_invite_codes`, ma sono i codici di verifica campus — impalcatura, non
la porta.

Quindi E5 non è una riga di tabella. È: inviti aperti + codice a sei caratteri
+ deferred deep link + contabilità del budget + ricarica su attivazione + il
gate nel flusso di auth + la dotazione da 30 ai Founder Circle. È l'item più
grande dell'onda 1, ed è stimato come uno dei quindici.

**b) La regola di ricarica non è calcolabile nell'onda in cui viene spedita.**
`V1.md` §3.3: un invito si ricarica quando l'invitato *"si attiva davvero (due
relazioni reciproche e una vibe)"*. La misura delle relazioni reciproche è
**I1, che sta in onda 2**. L'onda 1 spedisce quindi un'economia degli inviti la
cui condizione di ricarica non si può calcolare fino a tre settimane dopo. È un
difetto meccanico, non un'opinione: o il budget non si ricarica per un mese, o
la ricarica si degrada a "ha installato" — che è precisamente ciò che §3.3
dichiara di voler evitare.

**c) Il budget strozza O2.**
`PRODOTTO.md` §6 dice che il campus 2 lo apre l'exchange che torna a Madrid con
il suo Ring vivo. Sotto la porta su invito, quella persona a Madrid può far
entrare **cinque persone**, e ne ricarica una solo quando una di quelle cinque
si attiva. Per aprire un cluster denso in una città nuova servono decine di
ingressi nella stessa settimana.

Il budget è un freno montato esattamente sul meccanismo da cui dipende
l'obiettivo O2. `V1.md` non se ne accorge perché tratta la porta e la scala in
due sezioni che non si parlano.

**d) Rompe il canone senza dirlo.**
`PRODOTTO.md` §4 descrive il loop di acquisizione come
`incontro reale → QR/link → entri nel Ring`, e `FUNZIONI.md` §2 E1 dice
*"inquadri un QR, o qualcuno inquadra il tuo"*. `V1.md` §3.2 cambia il lavoro
del QR: non fa più entrare nessuno. Nessuno dei due documenti a monte è stato
aggiornato.

`PRODOTTO.md` si apre dichiarando *"ogni feature si giudica contro questo
file"*. Se il file contro cui si giudica tutto descrive una porta che la v1 ha
chiuso, il criterio di giudizio non esiste più.

---

## 2 · Il verdetto per obiettivo

| | Obiettivo | La v1 lo serve? |
|---|---|---|
| **O1** | 2-3 cluster densi che completano il loop reciproco e tornano 4 settimane | 🟡 **in parte, e tardi.** Le funzioni giuste ci sono tutte (E3, E4, R2, R4, P3), ma la prova di ritenzione arriva a fine onda 2 — settimana 7 a velocità di piano, e la velocità di piano non è mai stata osservata |
| **O2** | Bocconi → campus 2 attraverso gli exchange | 🔴 **peggio di prima.** `VERIFICA-OBIETTIVI.md` lo trovava "scoperto" e prescriveva M2 (Ring in dieci secondi). La v1 mette M2 in onda 1 — giusto — e poi ci monta sopra un budget di inviti che rende impossibile popolare il Ring nuovo. Il buco è stato riempito e poi tappato |
| **O3** | Rete incompatibile con un business da reach | 🟢 **pieno, ma gratis.** Niente nelle 29 introduce reach; l'invito lo rende più vero. È anche l'unico obiettivo che non richiede lavoro: è un insieme di rifiuti |

Detto in una riga: **la v1 rafforza l'obiettivo che non costava niente,
ritarda quello che conta, e danneggia quello che era già scoperto.**

---

## 3 · Il conto vero dell'onda 1

### 3.1 · I ✅ dell'onda 1 sono veri nel database e falsi nel prodotto

Sei delle quindici righe dell'onda 1 sono marcate ✅ o `—`, cioè "già fatto".
Verificato: le tabelle e i servizi ci sono davvero. Ma:

`EventRingView.swift:436` — `join()` chiama `RingsService.join(token:)` e
`checkIn(eventRingId:)`. **Non crea nessun follow.** E `follows`
(`0001_init.sql:101-110`) ha `tier`, `proposed_tier`, `proposed_by`,
`created_at` — nessun `origin_ring_id`, nessun `met_at`.

Quindi E1 "prova di co-presenza ✅" è vero come riga di database e falso come
funzione: la prova esiste, non diventa mai una relazione, e non resta attaccata
a niente. Lo stesso vale a cascata per P1, P2, R1 (vibe, momento, reazione):
funzionano, ma operano su un grafo che un utente nuovo non ha.

**Quattro dei sei ✅ dell'onda 1 diventano utili solo dopo E3 ed E4.** Il conto
dei ✅ abbellisce il punto di partenza.

### 3.2 · Il calendario non è calibrato su niente

| Mese | Commit | Contenuto |
|---|---|---|
| 2026-04 | 31 | prodotto |
| 2026-05 | 16 | prodotto + design |
| 2026-06 | 26 | prodotto + polish |
| 2026-07 | 4 | 1 fix di prodotto (#31, il 12 luglio), 3 di piano |
| 2026-08 | 3 | **solo documenti** (#43, #44, #46) |

L'ultimo commit che contiene codice di prodotto è del **12 luglio**. Sono
ventisei giorni. Nello stesso periodo sono stati scritti cinque documenti,
questo compreso.

`git shortlog` dice una persona più agenti. L'onda 1 chiede a quella persona,
in quattro settimane: infrastruttura push, sistema di inviti aperti con
economia, roster, provenienza sul grafo, identità minima, cancellazione account
con export, icona, pagine legali, target iOS, Supabase prod, TestFlight.

`FEATURE-LANCIO.md` stimava il **sottoinsieme** in tre settimane, e già lì era
aggressivo. Non serve una stima alternativa: serve notare che **nessuna delle
due stime è derivata da un ritmo misurato**, e che l'unico ritmo misurato negli
ultimi due mesi è vicino a zero.

### 3.3 · Le due cose ferme sono ferme da due cicli di verifica

`VERIFICA-OBIETTIVI.md` §5, il 2026-08-06, chiudeva così: R1 (le venti
conversazioni di validazione) e R2 (i venti Founder Circle) sono i veri
vincoli, e sono umani.

Un giorno dopo:

- **R1** — `V1.md` §6 la sposta *dentro* l'onda 1. Cioè nella stessa finestra
  di quattro settimane che contiene tutto lo sblocco della distribuzione. È
  l'item più comprimibile della lista ed è l'unico che può invalidare tutto il
  resto.
- **R2** — `docs/growth/founder-circles-tracker.csv`: venti righe, tutte
  `status=target`, tutti i lead vuoti, invariato dall'8 giugno.

Due cicli di verifica hanno identificato lo stesso collo di bottiglia e nessuno
dei due ha prodotto un movimento. Il terzo ciclo è questo documento.

---

## 4 · Può avere successo come idea?

Separo la tesi dall'esecuzione, perché la risposta è diversa.

### 4.1 · Cosa è genuinamente forte

1. **La diagnosi di §2 è un'intuizione vera e non ovvia.** "Il 2016 non era uno
   stile, era una composizione della rete" è la cosa più intelligente nel repo.
   Tutti i concorrenti della categoria vendono l'estetica del 2016; questa è
   l'unica formulazione che spiega perché l'estetica non è mai bastata.
2. **Il moat in forma "non gli conviene" è più forte di "non sanno farlo"**, e
   le prove portate (Instants, BeReal venduta a Voodoo) sono reali e usate
   bene.
3. **Lo split acquisizione/ritenzione di §4 è la forma giusta per la
   categoria**, e risponde in anticipo ai due modi noti di morire: Locket
   (app-as-shell, nessun secondo motivo di aprire) e BeReal (rituale forzato).
4. **Il cuneo Bocconi è scelto per la ragione giusta** — la direzione in cui la
   rete punta, non la dimensione — e il vettore exchange è una risposta
   genuinamente non banale alla domanda che uccide i social campus-first.

Questo non è un progetto confuso. Il livello del ragionamento nei documenti è
sopra la media di quello che si vede in prodotti a questo stadio.

### 4.2 · Cosa regge tutto e non è verificato

**a) La ritenzione è un'ipotesi, e la v1 non la mette alla prova prima della
settimana 7.**
Che una bolla colorata sul lockscreen faccia tornare un diciannovenne per
quattro settimane non è una domanda di design, è empirica.
`VERIFICA-OBIETTIVI.md` §5 R3 lo diceva già. Ogni versione del piano la
rimanda, e questa la rimanda più delle precedenti.

**b) L'invito peggiora il problema che il prodotto ha davvero.** *(Rilievo
accolto il 2026-08-07: la porta su invito e il budget sono usciti dalla v1.
Il paragrafo resta perché è la ragione della decisione.)*
`VERIFICA-OBIETTIVI.md` §3 lo nomina: una rete chiusa ha poco contenuto, ed è
matematica. La risposta corretta è "la presenza, non il contenuto". Ma la
presenza richiede comunque **persone presenti**: un campo con tre bolle non è
un pavimento di ritenzione, è una stanza vuota arredata meglio.

L'invito con budget risolve un problema che Halo non ha ancora — troppi utenti
di bassa qualità — al costo di quello che ha: non abbastanza densità perché
valga la pena aprire l'app. La scarsità è un meccanismo di **desiderio**;
`PRODOTTO.md` §10 definisce il traguardo in termini di **densità**. Non sono la
stessa leva, e a questo stadio la seconda batte la prima.

Il precedente citato non regge nemmeno: Facebook era chiuso **al confine** di
Harvard, ma dentro Harvard era aperto istantaneamente a ogni studente. Halo
mette la chiusura anche **dentro** il cluster. Quello non è il pattern
Facebook, è il pattern Clubhouse/Cabal — che produce un picco, non un
pavimento.

**c) Il moat difende dal modo di morire che in questa categoria non ha mai
ucciso nessuno.**
`docs/research/competitive-audit.md` elenca quattordici prodotti adiacenti. La
lettura onesta di quella lista: Locket, BeReal, Lapse, Path — nessuno è morto
perché Meta l'ha copiato. Sono morti perché il comportamento non si è
sostenuto. Il repo tratta il moat come il proprio asset principale, e il moat
risponde a "perché non ci schiacciano", non a "perché qualcuno dovrebbe usarla
la terza settimana".

**d) Il vero incumbent è WhatsApp, e compare solo in una nota.**
`PRODOTTO.md` §10 si dà da solo il criterio di morte: *"c'è il gruppo WhatsApp,
funziona"*. Nel contesto italiano quella è la risposta più probabile, non la
meno — la vita sociale studentesca italiana gira su gruppi WhatsApp in modo
insolito anche per gli standard europei. È esattamente per questo che la
domanda di validazione è ben progettata, ed esattamente per questo non averla
fatta per due mesi è la decisione più costosa presa finora.

**e) La monetizzazione che si vuole è in onda 4, quella che non si vuole è già
costruita.**
`PRODOTTO.md` §3 lascia aperta la domanda su come si monetizza una rete senza
reach, e indica T3/Memory come la risposta naturale ("l'effimero gratis, il
ricordo a pagamento"). T3 è in **onda 4**. Nel frattempo Stripe, Clubs, Plus e
il checkout esistono già nel repo e vengono nascosti. È stato costruito il
modello di ricavo che il prodotto rifiuta e rimandato quello che rivendica.

### 4.3 · La risposta

**Sì, l'idea può funzionare.** La tesi è coerente, il posizionamento è
differenziato, il cuneo è scelto bene, e la disciplina dei "no" è reale.

**No, la v1 così com'è non è il modo di scoprirlo.** Il rischio dominante non è
"mancano funzioni": è "non sappiamo se qualcuno la vuole, e non sappiamo se
torna". Nessuna delle due incognite costa denaro. La v1 risponde a entrambe con
quattordici settimane di costruzione, e mette la prima prova utile oltre
l'orizzonte in cui il progetto ha dimostrato di saper consegnare qualcosa.

---

## 5 · Cosa cambierei, in una riga per punto

*Stato al 2026-08-07: **1, 2 e 7 sono stati applicati** in `docs/V1.md` (la
porta su invito e il budget escono, il canone torna coerente da solo). **3, 5 e
6 restano aperti.** **4 è stato respinto**: perimetro e data restano, vedi
§0-bis.*

1. **Spedire la porta, non l'economia.** Inviti aperti + codice a sei caratteri
   in onda 1; budget, ricarica e dotazione founder fuori. Il budget dipende da
   I1, che è in onda 2 (§1.3b), e frena O2 (§1.3c). Non è pronto e non serve a
   dieci persone.
2. **Chiudere l'invito al confine, non dentro il cluster.** Chi era fisicamente
   a un Ring lo può far entrare senza consumare budget: la co-presenza è già la
   risorsa scarsa, ed è molto più difficile da falsificare di un contatore. Il
   budget limita solo gli inviti a distanza. Questo salva la tesi e sblocca O2.
3. **Togliere "Home = le persone" dall'onda 1 come item separato** e sostituirlo
   con E3 + la migration di E4 (`origin_ring_id`, `met_at`): sono due giorni di
   lavoro che rendono veri quattro ✅ già in tabella (§3.1).
4. **Riportare l'onda 1 al criterio di `FEATURE-LANCIO.md`** — *si ferma o si
   annoia?* — e accettare che E7 e R3a completo non lo superano. U4 resta solo
   perché lo impone App Review 5.1.1(v), non perché serva a dieci persone.
5. **Fare R1 questa settimana, in parallelo al codice.** Venti conversazioni,
   due giorni, nessuna dipendenza. È al terzo documento consecutivo che la
   prescrive.
6. **Mettere R2 in mano a una persona con un nome e una data.** Il tracker è
   fermo da due mesi: non è un problema di priorità, è che non è di nessuno.
7. **Riallineare `PRODOTTO.md` §4 e `FUNZIONI.md` §2 alla porta su invito**, o
   dichiarare che la porta è reversibile. Finché i due documenti descrivono
   ingressi diversi, il criterio con cui si giudica ogni feature non esiste.
