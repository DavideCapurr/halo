# Halo — definizione di prodotto

> Documento di riferimento. Ogni feature, copy, schermata e riga di roadmap si
> giudica contro questo file. Se una cosa non si giustifica qui, non si fa.
>
> Questo file risponde a **cosa è Halo e perché esiste**.
> `PLAN.md` risponde a *cosa stiamo costruendo*.
> `TODO.md` risponde a *cosa facciamo adesso*.
> `docs/launch/PIANO-LANCIO-BOCCONI.md` risponde a *come lo portiamo fuori*.

---

## 1 · La tesi

**Halo è la rete delle persone che hai incontrato davvero.**

Non chi ti segue. Non chi conosci online. Chi hai incontrato.

Una frase sola, zero termini proprietari. Se per spiegare Halo serve il
glossario di Halo, la spiegazione è sbagliata.

### Versione per una matricola

> "È l'app dove restano le persone che conosci davvero — vedi come stanno
> senza doverci parlare."

### Versione per un investitore

> "Costruiamo la rete sociale europea composta esclusivamente da relazioni
> verificate dal mondo reale. Instagram non può copiarci: il suo modello di
> business richiede reach, e la reach richiede persone che non conosci."

---

## 2 · Perché esiste

Le persone rimpiangono i social del 2016. Il motivo di solito viene raccontato
come estetica — niente algoritmo, niente metriche, foto brutte, spontaneità.

È una diagnosi sbagliata. Nel 2016 il tuo feed conteneva **solo persone che
avevi incontrato davvero**. Niente creator, niente brand, niente consigliati.
Il 2016 non era uno stile: era una *composizione della rete*.

Da allora ogni piattaforma ha avuto un incentivo economico a romperla, perché
la pubblicità si vende sulla reach e la reach richiede estranei.

Halo non è "il 2016 di nuovo". Halo è **la ragione per cui il 2016 funzionava,
ricostruita di proposito e difesa dal modello di business.**

---

## 3 · Cosa ci distingue (e perché non è copiabile)

Il vantaggio difendibile **non** è nessuna di queste cose:

| Non è il moat | Perché no |
|---|---|
| Privacy | Yope, Instants, BeReal la offrono già, con distribuzione superiore |
| Niente algoritmo | Scelta di prodotto, replicabile in uno sprint |
| Contenuti effimeri | Standard di categoria dal 2013 |
| Design premium | Copiabile, e non trattiene nessuno |
| Verifica campus | Acceleratore locale, non generalizza (vedi §6) |

Il moat è uno solo, e è strutturale:

> **Una rete composta solo da persone incontrate dal vivo è incompatibile con
> un business da reach.**

Instagram vive di pubblicità. La pubblicità vive di reach. La reach richiede
che tu veda contenuti di persone che non conosci. Un grafo chiuso alle sole
relazioni reali non produce inventory pubblicitaria alla scala di Meta, non
sostiene una creator economy, non ha coda lunga di contenuti.

Meta ci ha già provato — **Instants** è il tentativo di rifare BeReal dentro
Instagram. E BeReal, dopo essere stata la cosa più calda del 2022, è finita
venduta a Voodoo. Il pattern si ripete: quando "solo amici veri" convive con
un business da reach, il business vince e la promessa si diluisce.

Il moat migliore non è *"non sanno farlo"*. È *"non gli conviene farlo"*.

**Conseguenza vincolante:** Halo non introdurrà mai reach algoritmica,
contenuti da estranei, creator economy o profili pubblici scopribili. Non per
purezza ideologica — perché è letteralmente l'unica cosa che ci protegge.

**Domanda aperta, da chiudere prima della Serie A:** come si monetizza una
rete senza reach a 50M di utenti. Candidati: abbonamento, licenze a
istituzioni, eventi, commercio locale ad alta intenzione. Non va risolta
adesso, ma non va nemmeno dimenticata.

---

## 4 · Il loop

Un prodotto è definito da cosa fa aprire l'app. Halo ha due motori distinti e
serve capire che fanno lavori diversi:

```
  ACQUISIZIONE                          RITENZIONE
  L'evento è la porta      ───────►     La presenza è il pavimento

  Incontro reale                        Widget in lockscreen
  → QR / link                           → vedi come stanno i tuoi
  → entri nel Ring                      → reagisci in un tap
  → le persone restano                  → torni domani senza sforzo
```

- **L'evento acquisisce.** Dà un motivo reale, in un momento reale, con
  persone reali, per installare qualcosa di nuovo. È l'unico modo onesto di
  far scaricare un social a qualcuno nel 2026.
- **La presenza trattiene.** È l'unico loop che non richiede all'utente di
  *decidere* di aprire l'app. Il widget lavora anche quando l'utente non fa
  niente.

Nessuno dei due basta da solo. L'evento è episodico (cosa ti fa aprire Halo a
novembre?). La presenza da sola non ha un motivo per esistere in un posto
nuovo invece che su Instagram.

### Il ciclo completo, misurabile

```
incontro reale → scan/link → verifica di co-presenza → Ring
  → ≥2 relazioni reciproche → segnale (vibe/momento) → risposta → ritorno
```

L'attivazione si conta **solo** quando c'è reciprocità e una risposta sociale.
Un Ring join isolato, o una vibe che nessuno vede, non è attivazione: è rumore
che ci racconta una bugia sul funnel.

---

## 5 · Core vs impalcatura

La distinzione più importante del documento. Bocconi è un trampolino, non il
prodotto — quindi ogni pezzo va classificato **prima** di costruirlo.

Il test: *"questa cosa la butto quando esco da Bocconi?"*

### Core — vale ovunque, per sempre

- **Prova di co-presenza** (Ring + QR/link con token temporale). È il cuore.
  "Eri lì" è la versione universale e permanente di "sei di Bocconi".
- **Grafo delle relazioni reali** e sua persistenza nel tempo.
- **Presenza leggera** (vibe, stato, reazioni) e il widget.
- **Contenuti a basso rischio**, effimeri di default.
- **Distanza relazionale**, come idraulica invisibile — mai come pannello di
  controllo (vedi §7).

### Impalcatura — acceleratore locale, deve staccarsi senza rompere niente

- Verifica `@studbocconi.it` e tabelle `campuses` / `campus_verifications`
- Course Ring, Club Ring, associazioni studentesche
- Orientation QR, Welcome Week, Founder Circles
- Qualsiasi copy che contenga la parola "Bocconi"

**Stato attuale (debito noto):** oggi è il contrario. La verifica campus è
cablata nelle RLS e nell'architettura, il Ring/QR è arrivato dopo. Va invertito
progressivamente. Non è un refactor urgente — è la lente con cui si giudica
ogni scelta nuova da qui in avanti.

**Regola pratica:** nessuna nuova feature core può dipendere dall'esistenza di
un campus.

---

## 6 · La scala: Bocconi → Europa

L'obiettivo dichiarato è la rete di default per gli under-25 europei. Non
"Instagram" (2 miliardi di utenti): **40-80 milioni di persone**. È
un'ambizione enorme e dichiarabile senza perdere credibilità.

### Perché Bocconi è il nodo giusto

Non perché è grande. Perché è **ambito e già puntato verso l'esterno**:

- studenti da tutta Europa e dal mondo, ~33% internazionali
- exchange in entrata **e in uscita** — arrivano, si costruiscono una rete,
  e tornano a casa portandosela dietro
- densità sufficiente a osservare effetti di rete su un campus solo
- gli alumni si distribuiscono su Milano, Londra, Parigi, Madrid
- desiderabilità: entrare in una rete chiusa e ambita è di per sé un motivo

È la stessa proprietà per cui Facebook partì da Harvard. Non la dimensione:
la direzione in cui la rete punta.

### Il gradino difficile non è Bocconi → Europa

È **Bocconi → campus 2.**

Il colpo di genio di Facebook non fu Harvard: fu che lo stesso identico
meccanismo funzionò a Yale *senza modifiche*, e che gli studenti di Harvard
avevano già amici a Yale che li vedevano usarlo. La rete tirò se stessa.

Quindi la domanda da saper rispondere prima di aprire il secondo campus:

> **Cosa porta Halo da Bocconi a Bocconi+1?**

- ❌ "Rifacciamo lo stesso lavoro manuale altrove" → non è un trampolino, è un
  tapis roulant. Ogni campus costa quanto il primo, non scali mai.
- ✅ "Gli exchange tornano a Madrid con il loro Ring già vivo" → è una
  macchina. Il campus 2 lo apre la rete, non il fondatore.

**Implicazione operativa immediata:** gli studenti in exchange non sono un
segmento come gli altri nel tracker. Sono **il vettore di espansione**, e
vanno trattati come la coorte più preziosa del pilot.

### La tensione da gestire consapevolmente

Esclusivo e di massa sono in contraddizione — ma **in sequenza** funzionano.
Facebook fu prima chiusissimo, poi aperto, e la chiusura iniziale fu il motore
del desiderio. Va fatto di proposito, sapendo dove sta la scala:

```
Bocconi  →  campus élite europei  →  università europee  →  under-25 europei
```

Ogni gradino si apre **solo** quando il precedente è denso, non quando è
grande.

### "Europeo" è un'arma, ma non verso l'utente

Nessun diciannovenne sceglie un'app perché ha sede in UE. Ma università,
stampa, regolatori, investitori e genitori sì — e nel 2026, con DMA, DSA e
sovranità digitale, il vento è reale.

**Regola:** l'argomento europeo non entra mai nell'onboarding o nella copy
consumer. Entra nelle stanze istituzionali.

---

## 7 · Vocabolario: cosa sopravvive

Il rischio più concreto del prodotto oggi è il gergo. Il documento
`docs/research/vocabulary.md` esiste perché il concetto non era chiaro — con
la tesi di §1, gran parte di quel dibattito si scioglie da solo.

**Massimo tre termini proprietari nel first run.**

| Termine | Sopravvive? | Nota |
|---|---|---|
| **Ring** | ✅ | Dove vi siete incontrati. Core, universale. |
| **Vibe** | ✅ | Come stai. Motore della ritenzione. |
| **Halo** | ✅ | Il nome. |
| Inner / Close / Orbit / Nebula | ⚠️ invisibili | Idraulica, non interfaccia. Vedi sotto. |
| Moment, Pulse, Orbit Home, HaloSpace, Memory | ❌ nel first run | Nomi interni o superfici, non concetti da insegnare all'utente. |
| "Social map" | ❌ | Crea aspettative di geolocalizzazione. Halo mappa relazioni, non posizioni. Da eliminare dalla copy. |

### I tier vanno derivati, non dichiarati

`ChooseYourFiveView` **esce dall'onboarding.**

Chiedere all'utente di fare la tassonomia della propria vita sociale prima di
avergli dato un solo momento di valore è il singolo errore di prodotto più
grave nel repo. Tre motivi, in ordine di gravità:

1. È il lavoro più intimo e faticoso possibile, richiesto a costo zero di
   fiducia guadagnata.
2. Per una matricola o un exchange al giorno 1 è **impossibile**: non
   conoscono ancora cinque persone. Sono esattamente il nostro utente.
3. Fuori da un campus, a un utente qualsiasi in un contesto qualsiasi, "scegli
   i tuoi cinque" al primo avvio non significa niente.

I tier si muovono da soli in base al comportamento: chi ti risponde, chi
reagisce, chi era al tuo stesso Ring. La correzione manuale resta possibile,
ma come rifinitura in un secondo momento — mai come porta d'ingresso.

---

## 8 · Cosa Halo non è

Elenco vincolante. Ognuna di queste, se introdotta, rompe la tesi di §3.

- ❌ Un feed pubblico, o contenuti da persone che non hai incontrato
- ❌ Reach algoritmica o raccomandazioni
- ❌ Creator economy, profili scopribili, directory pubblica
- ❌ Metriche pubbliche (follower, like count, view count)
- ❌ Una mappa geografica / posizione live
- ❌ Una app di messaggistica (WhatsApp esiste e ha vinto)
- ❌ Un ticketing / RSVP tool (Partiful e Apple Invites esistono e sono gratis)

### Congelato fino a prova di ritenzione

Non perché sbagliato — perché non riduce il rischio dominante, che è
**domanda e ritorno**:

- Halo+ , paywall, skin, StoreKit, Stripe
- Discovery, profili pubblici
- Clubs B2B e billing associato
- Nuove categorie di Ring
- Ulteriore polish visuale

---

## 9 · Come si giudica una feature

Cinque domande. Serve **sì** a tutte e cinque.

1. **Serve la tesi?** Rafforza "solo persone incontrate davvero"?
2. **Sopravvive a Bocconi?** O è impalcatura mascherata da core? (§5)
3. **Acquisisce o trattiene?** Se nessuna delle due, è decorazione.
4. **Costa un termine nuovo?** Se sì, quale dei tre esistenti elimini? (§7)
5. **Instagram potrebbe copiarla senza danneggiare il proprio business?**
   Se sì, non è un vantaggio — al massimo è igiene.

---

## 10 · Prossimo milestone

**Non** "pubblicare Halo". **Non** "arrivare a 100 download".

> Portare 2-3 cluster densi e sovrapposti a completare il loop reciproco, in
> sicurezza, e dimostrare che tornano per quattro settimane.

Prima di scrivere altro codice, la tesi va verificata su persone vere. La
domanda da fare — e nota che **non contiene la parola Bocconi**, quindi si può
fare a chiunque, subito, senza aspettare la Welcome Week:

> *"Pensa all'ultima persona interessante che hai conosciuto a un evento.
> Che fine ha fatto?"*

Se la risposta abituale è "ci siamo aggiunti su Instagram e finita lì,
peccato" → il problema è reale e Halo ha una ragione di esistere.
Se è "c'è il gruppo WhatsApp, funziona" → la tesi va rivista prima di
qualunque altra cosa.

Gate e metriche di attivazione, ritenzione e densità relazionale:
`docs/launch/PIANO-LANCIO-BOCCONI.md`.
