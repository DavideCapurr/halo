# Le quattro correzioni alla tesi

> `docs/VERIFICA-V1.md` §4.2 ha lasciato quattro problemi aperti nell'idea, non
> nel piano. Questo file li chiude — o dice perché uno non si può chiudere a
> tavolino.
>
> Le correzioni che ne escono sono state applicate a `docs/PRODOTTO.md` e
> `docs/V1.md`. Qui c'è il ragionamento.
>
> Data: 2026-08-07.

---

## 0 · Cosa è risultato

Tre dei quattro erano problemi di **argomento**, e si sistemano. Uno è
empirico e non si sistema scrivendo — ma il modo in cui il piano lo misura era
sbagliato, e quello sì.

| | Problema | Esito |
|---|---|---|
| **a** | La ritenzione è un'ipotesi | **Non chiudibile a tavolino, ma la soglia di attivazione era sbagliata.** §1 |
| **c** | Il moat difende dal modo di morire sbagliato | **Chiuso: mancava il secondo moat, e ce l'avevamo già in mano.** §2 |
| **d** | WhatsApp è l'incumbent reale | **Chiuso, ed era il problema più grave: il criterio di morte avrebbe ucciso il progetto su una risposta che lo conferma.** §3 |
| **e** | La monetizzazione è invertita | **Chiuso, e la correzione coincide con quella di (c).** §4 |

La più importante è **(d)**, e non per la ragione che sembra.

---

## 1 · (a) La ritenzione — la soglia era sotto il pavimento

Che una bolla colorata su un lockscreen faccia tornare qualcuno per quattro
settimane resta empirico: si scopre costruendo. Ma l'ipotesi non è una, sono
tre, e solo la seconda richiede davvero di costruire.

- **H1 — alle persone interessa come stanno i loro amici, passivamente.**
  Si verifica con le venti conversazioni di R1. Non serve codice.
- **H2 — il widget è un veicolo sufficiente a creare abitudine.** Questa
  richiede di costruire. È l'unica vera incognita.
- **H3 — nel widget c'è abbastanza da vedere perché guardarlo abbia senso.**
  Questa **non è un'ipotesi: è aritmetica**, e nessuno l'aveva fatta.

### H3, fatta

Il widget mostra le vibe delle relazioni reciproche. Una vibe dura 24 ore.
Chiamiamo `N` le reciproche attive e `p` la probabilità che una persona metta
una vibe in un giorno. Le vibe visibili in un momento qualsiasi sono ≈ `N × p`.

| `N` reciproche | `p = 0,2` (1 volta/sett.) | `p = 0,3` (2 volte/sett.) | `p = 0,5` |
|---|---|---|---|
| 2 | 0,4 | 0,6 | 1,0 |
| 5 | 1,0 | 1,5 | 2,5 |
| 8 | 1,6 | 2,4 | 4,0 |
| 12 | 2,4 | 3,6 | 6,0 |

Un widget con **0,6 vibe attive in media è vuoto due giorni su tre.** Nessuna
qualità di design lo salva: non è un problema di superficie, è che non c'è
niente da mostrare.

### La correzione

`docs/PRODOTTO.md` §4 definisce l'attivazione come **"≥2 relazioni
reciproche"**. Sotto qualunque valore plausibile di `p`, due reciproche
lasciano il widget spento. Vuol dire che **il piano dichiarerebbe "attivato"
un utente strutturalmente garantito di andarsene** — e poi si domanderebbe
perché la ritenzione a quattro settimane è bassa, cercando la causa nel posto
sbagliato.

> L'attivazione non è "ha completato il loop una volta". È **"ha abbastanza
> rete perché il loop si ripeta da solo"**.

Soglia adottata: **≥6 relazioni reciproche e una risposta sociale ricevuta.**
Sei è il punto in cui, anche con `p` pessimistico, il widget ha in media più di
una vibe attiva. Non è un numero misurato — è un numero *derivato*, il che è
già meglio del due che c'era, che non era né l'uno né l'altro.

**Cosa deve fare l'onda 2:** I1 misura `p` sul campo. Con `p` reale la soglia
si ricalcola in dieci minuti, e diventa misurata.

**Conseguenza operativa immediata:** il lavoro dell'onda 1 non è portare
persone dentro, è portare **ognuna a sei**. E1+E3 (roster) da soli non bastano
se il Ring ha otto persone e ne aggiungi due. Il roster deve rendere
l'aggiunta di *tutti i presenti* il gesto di default, non un'azione per riga.

---

## 2 · (c) Il moat — ne mancava uno, e ce l'avevamo già

Il rilievo: `PRODOTTO.md` §3 dimostra che a Meta **non conviene** copiarci. È
un buon argomento ed è corretto. Ma Locket, BeReal, Lapse e Path sono morti
tutti senza che nessuno li copiasse. Il moat difende da un modo di morire che
in questa categoria non ha mai ucciso nessuno.

### Cosa li ha uccisi davvero

| | Meccanica | Come è finita |
|---|---|---|
| Path | 150 contatti, relazioni vere, design migliore di Instagram | aprivi e non c'era niente |
| BeReal | rituale quotidiano forzato | il rituale è diventato performativo, poi una seccatura |
| Locket | una foto nel widget | nessun secondo motivo di aprire l'app |
| Lapse | ritardo di sviluppo della foto | la novità è finita e è rimasto l'attrito |

Il pattern è uno solo: **avevano una meccanica e nessun asset che si accumula.**
Quando la meccanica ha stancato, l'utente non aveva niente da perdere andandosene.

Instagram ha l'archivio di foto e il grafo di follower. WhatsApp ha lo storico
e il fatto che ci sono tutti. Entrambi rendono l'uscita costosa. Nessuno dei
quattro morti aveva un equivalente.

### Il secondo moat, che è già nel repo

Halo ha un candidato, ed è già identificato in `PERIMETRO.md` C2 e costruito da
E4: **la provenienza della relazione.** *"Conosciuta il 3 ottobre, Aperitivo
giovedì"*, per sempre, su ogni legame.

Ha le tre proprietà che servono:

1. **Nessun altro ce l'ha.** Instagram non sa dove hai conosciuto nessuno.
   WhatsApp nemmeno. È un dato che esiste solo se lo raccogli al momento
   dell'incontro — e noi siamo lì, per costruzione.
2. **Si accumula, e accelera.** A un mese è un dettaglio. A due anni è la mappa
   dei tuoi vent'anni, e non è ricostruibile a posteriori da nessuna parte.
3. **Rende l'uscita costosa senza trattenere nessuno con la forza.** Non è una
   streak, non è un ricatto: è semplicemente una cosa tua che esiste solo lì.

### La correzione

`PRODOTTO.md` §3 aveva un moat solo. Ora ne ha due, e fanno lavori diversi:

> **Moat competitivo** — perché non ci schiacciano: una rete di sole relazioni
> reali è incompatibile con un business da reach.
>
> **Moat di ritenzione** — perché l'utente non se ne va: la provenienza è un
> archivio della propria vita sociale che si accumula e che non esiste altrove.

Il primo era già scritto e va bene. Il secondo mancava, ed è quello che
risponde alla domanda che ha ucciso i quattro predecessori.

**Conseguenze applicate:**

- **E4 non è una riga fra ventinove.** È il fondamento del secondo moat, e resta
  in onda 1 dov'è — ma con lo stato di prerequisito, non di completamento.
- **La provenienza va raccolta dal giorno 1 anche se non si mostra ancora.**
  È l'unica delle ventinove funzioni che, se arriva tardi, perde
  retroattivamente valore: le relazioni nate prima non hanno un'origine
  ricostruibile. Ogni settimana di ritardo è una settimana di archivio persa
  per sempre.

---

## 3 · (d) WhatsApp — il criterio di morte era scritto al contrario

Questo era il problema più grave dei quattro, e non perché WhatsApp sia forte.

### Il difetto

`PRODOTTO.md` §10 si dà da solo il criterio di validazione:

> *"Pensa all'ultima persona interessante che hai conosciuto a un evento. Che
> fine ha fatto?"*
>
> Se la risposta è "ci siamo aggiunti su Instagram e finita lì" → il problema è
> reale. Se è **"c'è il gruppo WhatsApp, funziona"** → la tesi va rivista.

In Italia la seconda risposta è quella che si sentirà quasi sempre. Non perché
il problema non esista: perché **il gruppo WhatsApp esiste sempre**. Si fa in
dieci secondi, è gratis, ci sono già tutti.

Quindi il criterio di morte, come è scritto, **fa fallire il test su una
risposta che non dice niente sul problema.** È un falso negativo garantito. Se
R1 si fosse fatta in luglio come prescritto tre volte, sarebbe probabilmente
tornata con "sì, il gruppo c'è" — e il progetto si sarebbe fermato sulla
risposta sbagliata.

### La correzione: la domanda ha un secondo tempo

Il gruppo WhatsApp non è il concorrente di Halo. È il **contenitore
dell'evento**, e muore con l'evento. Le domande giuste vengono dopo:

> 1. *"Quel gruppo, è ancora vivo?"*
> 2. *"Di quelle persone, con quante parli ancora?"*
> 3. *"Se domani qualcuno lo archivia, cosa ti resta di quelle persone?"*

La risposta prevalente attesa: il gruppo è morto in tre settimane, delle
quattordici persone ne è rimasta una, e di tutte le altre non resta niente —
nemmeno il nome, spesso nemmeno il ricordo di dove ci si è conosciuti.

**Quello è il problema.** Non "manca un posto dove parlare": ne esiste uno e
funziona benissimo. È che **quando il posto muore, muoiono anche le relazioni**,
perché non erano da nessuna parte.

### Il riposizionamento

Non si compete con il gruppo WhatsApp. È una guerra che si perde, e non serve
a niente vincerla.

> **Il gruppo WhatsApp è il contenitore dell'evento. Halo è quello che resta
> quando il gruppo muore.**

Questo è un posizionamento migliore, non un ripiego, per tre ragioni:

1. **Non chiede a nessuno di smettere di fare qualcosa.** Il gruppo si continua
   a fare. Halo non è in competizione per lo stesso gesto.
2. **È già il prodotto.** E8 dice letteralmente *"il Ring finisce, le persone
   restano"*. Era una funzione; è la frase con cui si spiega Halo.
3. **Rende concreto il secondo moat di §2.** Il gruppo WhatsApp non lascia
   residuo. Halo *è* il residuo.

**Correzione applicata a `PRODOTTO.md`:** §10 non tratta più "c'è il gruppo
WhatsApp" come risposta di morte, ma come risposta *attesa*, con le tre domande
di secondo tempo. Il vero criterio di morte diventa: **se le persone dicono che
quei gruppi sono ancora vivi e che con quelle persone parlano ancora**, allora
il problema non esiste e la tesi va rivista.

---

## 4 · (e) La monetizzazione — la correzione è la stessa di (c)

Il rilievo: T3/Memory è la cosa per cui `PRODOTTO.md` §3 dice che ha senso
pagare ("l'effimero gratis, il ricordo a pagamento"), ed è in **onda 4**.
Intanto Stripe, Clubs, Plus e il checkout sono già costruiti e si stanno
nascondendo.

Con §2 il rilievo cambia di natura: **Memory non è la monetizzazione, è la
faccia visibile del moat di ritenzione.** Metterla in onda 4 non è tardi per
fare cassa — è tardi per la cosa che dovrebbe impedire la fuga.

Ma non segue che vada spedita tutta subito. T3 si spacca in tre pezzi che oggi
sono confusi in uno:

| | Cosa | Quando | Costo |
|---|---|---|---|
| **T3a** | **Accumulare.** Ciò che scade non si cancella davvero: si marca scaduto e resta legato alla sua origine | **onda 1** | XS — è la stessa migration di E4 più un `deleted_at` invece di un `DELETE` |
| **T3b** | **Mostrare.** Una superficie che fa vedere cosa si è accumulato | onda 3 | S/M |
| **T3c** | **Far pagare.** Il paywall sull'archivio | onda 4 o dopo | invariato |

L'ordine conta: **T3a in onda 1 non costa quasi niente e non è recuperabile
dopo.** Se in onda 1 si cancella per davvero, l'archivio dei primi tre mesi —
cioè quello dei primi utenti, cioè i Founder Circle — non esisterà mai.

T3c resta dov'è, e per una ragione in più: far pagare a mese 1 un archivio di
tre settimane è assurdo. **Il paywall ha senso solo quando l'asset ha un peso**,
il che è esattamente ciò che dice §2. La monetizzazione non va anticipata;
l'accumulazione sì.

Su Stripe/Clubs/Plus già costruiti: nessun cambiamento. Restano nascosti. Che
siano stati costruiti prima è un fatto sul passato, non una decisione da
prendere di nuovo.

---

## 5 · Cosa cambia, in pratica

Applicato a `docs/PRODOTTO.md`:

1. §3 ha due moat, non uno — competitivo e di ritenzione.
2. §4 definisce l'attivazione a **≥6 reciproche + una risposta**, con la
   derivazione in nota.
3. §10 riscrive il criterio di validazione: il gruppo WhatsApp è la risposta
   attesa, non quella di morte; il criterio di morte è il suo contrario.
4. §3 aggiunge il posizionamento: *"il gruppo è il contenitore, Halo è quello
   che resta"*.

Applicato a `docs/V1.md`:

5. **T3a (accumulare) sale in onda 1.** T3b in onda 3, T3c resta in onda 4.
6. E3 (roster) ha un criterio di "fatto" nuovo: **aggiungere tutti i presenti
   in un gesto**, non uno per riga — perché il traguardo è sei, non due.

Cosa resta aperto e non chiudibile qui: **H2**, cioè se il widget crei
abitudine. Quella si scopre in onda 2, ed è l'unica delle quattro che chiedeva
davvero di costruire.
