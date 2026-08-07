# L'app, funzione per funzione

> **Elenco canonico.** Se cerchi "cosa fa Halo", si guarda qui e basta.
>
> Le funzioni sono state **scelte tutte e 29**, in quattro onde: la decisione,
> l'ordine e i criteri di "fatto" sono in `docs/V1.md`.
>
> `docs/PERIMETRO.md` e `docs/VERIFICA-OBIETTIVI.md` contengono il
> ragionamento con cui questa lista è stata costruita e messa alla prova;
> `docs/launch/FEATURE-LANCIO.md` dice quali di queste voci servono entro
> agosto. Questo file dice **cos'è l'app**.
>
> Stato verificato sul codice al 2026-08-06: ✅ c'è · 🟡 a metà · ❌ manca.

---

## 1 · L'app è sei schermate

Prima delle funzioni serve sapere quante superfici esistono, perché è il
vincolo che tiene tutto insieme. Halo finito ha **sei schermate più il
widget**:

| | Schermata | A cosa serve |
|---|---|---|
| 1 | **Le persone** | chi c'è oggi e come sta — è la home |
| 2 | **La fotocamera** | incontrare: scansionare, essere scansionati, creare un Ring |
| 3 | **Il Ring** | dove vi siete incontrati e chi c'era |
| 4 | **Il momento** | mandare un segnale: una vibe o una cosa breve |
| 5 | **Una persona** | la sua vibe, i suoi momenti, dove vi siete conosciuti |
| 6 | **Tu** | il tuo profilo, la pausa, la sicurezza, l'account |
| + | **Il widget** | le persone sul lockscreen, senza aprire niente |

Oggi il repo ne ha il doppio: Discovery, HaloSpace, Pulse, Stato, tre schermate
di compose separate, Clubs con billing, upsell Plus, ChooseYourFive. La metà
di quello che esiste non sta in questa griglia, ed è la ragione per cui l'app
è difficile da spiegare.

---

## 2 · ENTRARE — come una persona entra nella tua rete

### E1 · Prova di co-presenza ✅
**Il gesto:** inquadri un QR, o qualcuno inquadra il tuo.
**Cosa vede:** "eravate insieme al *Ring*" — con l'ora.
**Perché:** è il cuore di Halo. "Eri lì" è la versione universale e permanente
di qualunque verifica: funziona a Bocconi, a Madrid e a una cena.

### E2 · Ring in dieci secondi ❌ *(oggi form da dieci campi)*
**Il gesto:** scrivi un nome — "Aperitivo giovedì" — e ottieni un QR.
**Perché:** è la macchina della crescita. Se creare un Ring è facile come
mandare un link, la rete si apre da sola in una città nuova. Se richiede
prezzo, limite membri e approvazione, ogni Ring nuovo lo devi aprire tu.

### E3 · Roster — chi c'era ❌
**Il gesto:** dopo lo scan vedi le facce delle persone presenti, e per ognuna
un solo bottone: *aggiungi*.
**Perché:** è il passaggio in cui un incontro diventa una relazione. Oggi il
dato esiste nel database ma la schermata mostra due contatori.

### E4 · Provenienza della relazione ❌
**Cosa vede:** sotto ogni persona, per sempre: *"conosciuta il 3 ottobre,
Aperitivo giovedì"*.
**Perché:** è la funzione che rende letterale la frase "la rete delle persone
che hai incontrato davvero". Rende anche inutile la bio, e permette al grafo
di invecchiare senza sporcarsi.

### E5 · Invito che funziona ovunque ❌
**Il gesto:** mandi un link su WhatsApp. Chi lo apre senza l'app la installa e
arriva già collegato a te. Se il link si rompe, c'è un codice di sei caratteri.
**Perché:** oggi si può invitare solo chi è già iscritto — cioè, al giorno 1,
nessuno.

### E6 · Il primo minuto da solo ❌
**Cosa vede** chi installa l'app lontano da un evento: non una rete vuota, ma
una frase onesta — *"Halo non serve da solo: torna quando incontri qualcuno"* —
oppure l'onboarding finisce direttamente nella fotocamera.
**Perché:** è la maggioranza dei download della settimana di lancio, e oggi
per loro l'app è una schermata bianca.

### E7 · Identità minima 🟡
**Cosa serve per esistere:** una faccia, un nome. Niente bio, niente numeri,
niente da curare.
**Perché:** ogni campo in più è un invito a costruirsi un personaggio, cioè
esattamente il costo che Halo esiste per azzerare.

### E8 · Quando il Ring finisce ❌
**Cosa vede:** il Ring scade, le persone restano. Il momento della scadenza è
anche quello in cui l'app chiede l'unica cosa che conta: chi vuoi tenere.

---

## 3 · ESSERCI — cosa fai quando non succede niente

### P1 · La vibe ✅
**Il gesto:** scegli come stai. Otto stati, un colore, una riga se vuoi.
**Dura:** 24 ore, poi sparisce.
**Perché:** è l'unico contenuto che non richiede che ti sia successo qualcosa.
In una rete di sole persone reali il volume è basso per definizione: la
presenza è ciò che riempie i giorni vuoti.

### P2 · Il momento ✅
**Il gesto:** una foto, una riga, o dieci secondi di voce.
**Dura:** tre ore o tre giorni, lo scegli tu.
**Perché:** contenuti a basso costo di produzione. Il costo basso *è* la
feature — se posti solo quando hai qualcosa all'altezza, non posti.

### P3 · Il widget 🟡 *(oggi in sola lettura)*
**Cosa vede:** le persone e i loro colori sul lockscreen.
**Perché:** è l'unico loop che non chiede all'utente di decidere di aprire
l'app. È il pavimento della ritenzione, e per questo deve permettere anche di
**reagire da lì**, senza entrare.

### P4 · Chi vede cosa, senza chiedertelo 🟡
**Il gesto:** nessuno. Non c'è un selettore di pubblico.
**Perché:** la distanza fra te e gli altri la calcola l'app dal comportamento.
Il momento in cui chiedi a qualcuno di classificare i propri amici, gli hai
chiesto il lavoro più intimo possibile prima di avergli dato qualcosa.

### P5 · Il primo segnale lo dà il Ring ❌
**Cosa vede:** il giorno dopo l'evento, una card nel feed di tutti i presenti —
*"eravate in 14"* — su cui si può reagire.
**Perché:** in un gruppo nuovo tutti aspettano che pubblichi qualcun altro.
Qualcuno deve rompere il ghiaccio, e non può essere l'utente.

### P6 · L'evento mentre succede ❌ *(dopo)*
Durante un Ring attivo, Halo sta nella Dynamic Island: "12 persone qui".

---

## 4 · RISPONDERE — come si chiude il cerchio

### R1 · Reazione ✅
Un tap, sei glifi. Nessun contatore visibile.

### R2 · Risposta privata ❌
**Il gesto:** rispondi a una vibe con una riga. La legge solo chi l'ha
scritta, e scade con lei.
**Perché:** senza, la prima reazione a un segnale è aprire WhatsApp — e Halo
diventa una dashboard degli stati altrui.

### R3 · Notifiche — quattro, mai una quinta ❌
1. qualcuno ti ha invitato · 2. una persona vicina ha una vibe nuova ·
3. qualcuno ha risposto a una cosa tua · 4. il giorno dopo un Ring.
**Perché:** in un prodotto effimero senza notifiche i contenuti scadono prima
di essere visti. E la quinta categoria è sempre l'inizio della fine.

### R4 · Il ritorno del giorno dopo ❌
**Cosa vede:** 18-24 ore dopo un evento — *"ieri eri con sei persone"* — e un
tap per mandare la prima vibe o aggiungere chi manca.
**Perché:** l'evento acquisisce ma è episodico. Questo è il ponte tra il
motore che porta le persone dentro e quello che le fa tornare.

---

## 5 · RESTARE — cosa succede col tempo

### T1 · La distanza si muove da sola 🟡
Chi ti risponde e chi era ai tuoi Ring si avvicina; chi sparisce si allontana.
Correggibile a mano, ma mai come domanda iniziale.

### T2 · Le relazioni invecchiano ❌
Una relazione che non produce niente per mesi scivola indietro, in silenzio.
**Confine:** questo serve al sistema, non all'utente. Nessuna schermata deve
mai dire "non parli con Marco da tre mesi" — il giorno in cui Halo ti fa
sentire in debito verso i tuoi amici, ha perso.

### T3 · La memoria 🟡 *(dopo)*
L'archivio di ciò che sarebbe scaduto. È l'unica cosa per cui ha senso pagare
in un prodotto effimero: l'effimero gratis, il ricordo a pagamento.

### T4 · La rete viaggia ❌ *(dopo)*
Chi si sposta porta con sé le persone: il widget funziona a qualunque
distanza, e chi arriva in una città nuova apre un Ring lì. È così che si apre
il secondo campus senza rifare il lavoro da capo.

---

## 6 · USCIRE — le funzioni che fanno restare

### U1 · Mettersi in pausa ❌
Sparire per un giorno senza uscire da niente.

### U2 · Allontanare in silenzio 🟡
Nessuna notifica, nessun gesto visibile all'altro.
**Perché U1 e U2 esistono:** in una rete di persone che ti conoscono davvero,
se non puoi allontanarti senza che si veda, l'unica uscita è smettere di
aprire l'app. Sono funzioni di ritenzione, non di igiene.

### U3 · Blocco e segnalazione ✅

### U4 · I tuoi dati ❌
Cancellare l'account dall'app, esportare le proprie cose. Obbligatorio per
App Store, e comunque coerente con il prodotto.

---

## 7 · Funzioni che l'utente non vede

- **Misura della densità** ❌ — quante relazioni reciproche per persona e
  quanto si sovrappongono i cluster. È l'unico numero che dice se sta
  funzionando; oggi si contano gli eventi, cioè i download.
- **Il risultato dell'host** ❌ — a chi crea un Ring, in privato: "hai fatto
  incontrare 14 persone". È l'incentivo che produce il Ring successivo.
- **Scadenza automatica** ✅ — vibe, momenti e Ring spariscono da soli.

---

## 8 · Cosa l'app non fa, mai

Feed pubblico · consigliati e algoritmo · creator · profili scopribili ·
follower e like visibili · mappa o posizione · messaggistica · biglietti e
RSVP · promemoria di tipo CRM · numeri accanto alle persone.

Metà del prodotto è questa lista. Ogni voce, se entra, rende Halo copiabile
da chi ha già un miliardo di utenti.

---

## 9 · Come si dice a voce

Tre parole proprietarie in tutto: **Halo**, **Ring**, **vibe**. Tutto il resto
si dice in italiano normale — "le persone", "chi c'era", "come stai", "il
giorno dopo".

> "È l'app dove restano le persone che hai conosciuto davvero. Inquadri un
> codice quando incontri qualcuno, e da lì resta lì: vedi come sta senza
> doverci parlare."

Se per spiegarla serve altro, la funzione di cui stai parlando è sbagliata.

---

## 10 · Il conto

| | Funzioni | ✅ | 🟡 | ❌ |
|---|---|---|---|---|
| Entrare | 8 | 1 | 1 | 6 |
| Esserci | 6 | 2 | 2 | 2 |
| Rispondere | 4 | 1 | 0 | 3 |
| Restare | 4 | 0 | 2 | 2 |
| Uscire | 4 | 1 | 1 | 2 |
| Invisibili | 3 | 1 | 0 | 2 |
| **Totale** | **29** | **6** | **6** | **17** |

Sei schermate, ventinove funzioni, di cui dodici già in piedi in qualche
forma. Non è un prodotto grande: è un prodotto stretto, e deve restare tale.
