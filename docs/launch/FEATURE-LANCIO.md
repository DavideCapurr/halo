# Quali feature servono al lancio — e quali no

> Audit del codice del **2026-08-06** (verificato file per file, non sui
> documenti) + proposta di feature **nuove** non presenti in
> `PIANO-LANCIO-BOCCONI.md`.
>
> Questo file risponde a *cosa costruiamo nelle prossime settimane e in che
> ordine*. Il perché sta in `docs/PRODOTTO.md`, il come operativo in
> `PIANO-LANCIO-BOCCONI.md`, lo stato riassunto in `TODO.md`.

---

## 0 · Verdetto in tre righe

1. Il piano di lancio è stato scritto il 2026-07-05 su un orizzonte di 8
   settimane. Oggi è il **2026-08-06**: è passato un mese e **Fase 0 — i
   blocker di distribuzione — è ancora aperta per intero**. Il calendario
   reale non è più 8 settimane, sono ~3.
2. Tutto il lavoro effettivamente merged nell'ultimo mese è **documentazione e
   polish visivo**. I 10 PR aperti sono, senza eccezioni, superfici glass,
   raggi, chip e bottoni — cioè esattamente ciò che `docs/PRODOTTO.md` §8
   dichiara congelato fino a prova di ritenzione.
3. Manca una feature che nel piano non c'è affatto e che è il centro del loop:
   **dopo lo scan non si vede chi c'era, e non si può aggiungere nessuno.**
   È il punto in cui il funnel si interrompe (§3, N1).

---

## 1 · Stato verificato (codice, non documenti)

| Area | Piano dice | Codice dice | Stato reale |
|---|---|---|---|
| App icon / `Assets.xcassets` | §0.1 blocker | nessun asset catalog nel repo | ❌ aperto |
| Cancellazione account | §0.2 blocker | nessuna edge function, nessuna voce in `ProfileView` | ❌ aperto |
| Privacy / termini / regole | §0.3 blocker | `web/landing/` ha solo `index.html` + `join/` | ❌ aperto |
| Deployment target | §0.4 → 17.0 | `project.pbxproj` ha ancora due config a **26.0** | ❌ aperto |
| Supabase prod | §0.5 | script pronto, mai eseguito | ❌ aperto |
| Push / APNs | §1.1 "la più importante" | **zero** occorrenze di `UNUserNotification`, `apns`, `device_token` | ❌ aperto |
| Universal links | §1.2 | AASA + entitlement + parser `DeepLink` https ✅ ma `TEAMID` e `halo.app` sono placeholder, e la pagina di fallback esiste solo per `/join` | 🟡 metà |
| Inviti "aperti" | §1.2 | `invites.invitee_id` è **NOT NULL**: si può invitare solo chi è già iscritto | ❌ aperto |
| QR orientation → https | §1.4 | fatto in #31 (`?ring=` + pagina `/join`) | ✅ |
| Reply 1:1 effimera | §1.3 | nessuna tabella `replies` | ❌ aperto |
| OTP `@studbocconi.it` | §2.1 | solo suffisso + `BOCCONI-FOUNDERS-2026` committato in repo pubblico (`max_uses` 200) | ❌ aperto |
| Waitlist landing | §2.2 | `data-endpoint=""` in entrambi i form: i signup muoiono nel browser | ❌ aperto |
| Analytics funnel | §3.2 | strumentato davvero (signup, ring_joined, vibe_set, invite_*, move_closer) | ✅ |
| `ChooseYourFiveView` | PRODOTTO §7: **esce** | ancora cablata in `RootView.swift:25` | ❌ aperto |
| Co-presenza → relazioni | *assente dal piano* | `ring_members` e `event_checkins` esistono con RLS; la UI li mostra come **due contatori** (`members 07`, `check-in 03`) e nessuna azione | ❌ **buco** |

Nota su quest'ultima riga: `RingsService.members(for:)` e `checkIns(for:)`
esistono e funzionano, ma `EventRingView.swift:205-210` li rende come
`SwarmMetricTile`. Il dato della co-presenza c'è; non c'è la schermata che lo
trasforma in relazioni. È il pezzo con il rapporto valore/costo più alto di
tutto il repo.

---

## 2 · Il criterio con cui ho tagliato

Le cinque domande di `docs/PRODOTTO.md` §9 restano il filtro, ma per il
**lancio** ne aggiungo una che le ordina:

> **Se questa feature manca, la matricola si ferma o si annoia?**
>
> Si ferma = P0. Si annoia dopo tre giorni = P1. Nessuna delle due =
> non entra.

Il piano attuale mette la reply 1:1 fra i "comprimibili". È sbagliato: è
l'unica cosa che impedisce alla conversazione di uscire da Halo il giorno 1.
Vedi §4.

---

## 3 · P0 — senza queste non si lancia

### Gruppo A · Blocker di distribuzione (l'app non esiste)
Nessuno è iniziato, tutti sono corti, tutti bloccano l'upload.

| # | Feature | Size | Perché è P0 |
|---|---|---|---|
| A1 | App icon + `Assets.xcassets` | S | `xcodebuild archive` non produce un archivio caricabile |
| A2 | Cancellazione account in-app + edge function `delete-account` | M | Guideline 5.1.1(v): rejection quasi certa |
| A3 | `/privacy`, `/termini`, `/regole` su landing + link in app | S/M | URL obbligatori, e la 4.1 UGC chiede regole contenuti |
| A4 | Deployment target app a 17.0 | S | oggi due config a 26.0 tagliano chiunque non abbia aggiornato; i fallback `#available` esistono già |
| A5 | Supabase prod deployato + `purge-expired` schedulato | S | lo script c'è, va solo eseguito |
| A6 | Apple Developer: App ID, Push, Associated Domains, provisioning | manuale | ha tempi morti burocratici: va avviato **oggi**, non quando il codice è pronto |

### Gruppo B · Funnel (l'app esiste ma il lancio non attecchisce)

| # | Feature | Size | Perché è P0 |
|---|---|---|---|
| B1 | **Roster di co-presenza + "aggiungi chi c'era"** (§4, N1) | M | è il passo `Ring → ≥2 relazioni reciproche` della definizione di attivazione: oggi manca proprio quello |
| B2 | Inviti aperti + link https + **codice breve** (§4, N4) | M/L | `invitee_id NOT NULL` significa che non puoi invitare chi non è ancora iscritto: al giorno 1 sono *tutti* |
| B3 | Push MVP: invito ricevuto → vibe di un Inner | L | senza push l'effimero (vibe 24h) garantisce orbite vuote. Se scivola: almeno l'invito |
| B4 | AASA/entitlement con TEAMID e dominio reali + pagina `/i/{token}` | S | oggi l'universal link punta a `halo.app` e a un team placeholder: non funziona su nessun telefono |
| B5 | `data-endpoint` waitlist collegato a prod | XS | 15 minuti; oggi ogni iscrizione si perde |

**Se una sola cosa può slittare in questo gruppo, è B3 (push) ridotto al solo
invito.** B1 e B2 no: senza di loro il QR porta persone dentro una stanza
vuota.

---

## 4 · Feature nuove (non nel piano)

Ognuna passata alle cinque domande di `docs/PRODOTTO.md` §9.

### N1 · Roster di co-presenza — "chi c'era" · P0 · M
Dopo check-in o join, il Ring mostra **le persone**, non i contatori: chi era
lì nella stessa finestra temporale, ordinato per sovrapposizione, con una
azione sola per riga (*aggiungi*). Reciprocità visibile ("vi siete
incontrati"), nessun tier da scegliere.

- Serve la tesi? Sì — è letteralmente la prova di co-presenza resa utile.
- Sopravvive a Bocconi? Sì, è core §5: "eri lì" non dipende da un campus.
- Acquisisce o trattiene? Entrambe: chiude l'attivazione e popola il grafo.
- Costa un termine nuovo? No — Ring esiste già.
- Instagram può copiarla? Non senza rinunciare alla scoperta di estranei.

Costo basso: `ring_members`, `event_checkins`, `FollowsService.follow` e la
RLS esistono già. Manca solo la vista. **Sostituisce `ChooseYourFiveView`**:
i cinque non si dichiarano, si incontrano.

### N2 · "Il giorno dopo" — richiamo del Ring · P1 · S/M
18-24h dopo un check-in: una card (e una push) *"ieri eri con 6 persone"* →
un tap per mandare la prima vibe o aggiungere chi manca.

Risolve il difetto strutturale di §4 di PRODOTTO: l'evento acquisisce ma è
episodico. Questo è il ponte fra il motore di acquisizione e quello di
ritenzione, ed è l'unico momento in cui il ricordo è ancora caldo.
Passa tutte e cinque. Dipende da B3.

### N3 · Widget interattivo — reagire dal lockscreen · P1 · S/M
Il widget oggi è in sola lettura (nessun `AppIntent` in `HaloWidget/`).
`docs/PRODOTTO.md` §4 dice che la presenza è il pavimento della ritenzione
"senza che l'utente decida di aprire l'app" — ma per reagire oggi devi aprire
l'app. Un `AppIntent` (iOS 17+, quindi dipende da A4) rende la reazione un
tap sul lockscreen. È il loop di ritorno a costo zero.

### N4 · Codice breve + deferred deep link · P0 (dentro B2) · S
`/i/{token}` mostra un codice di 6 caratteri; in app, campo "hai un codice?".
Copre il caso reale dell'orientation week: telefono senza app, link aperto
dentro Instagram o WhatsApp, universal link che non scatta. Senza questo il QR
funziona in demo e fallisce in piazza.

### N5 · Reply effimera — **promuovere da comprimibile a P0-lite** · M
È già §1.3 del piano, ma classificata come rinviabile. Non lo è: senza un modo
di rispondere, la prima cosa che fa un utente che vede una vibe è aprire
WhatsApp — e Halo diventa una dashboard di stati altrui. Se non entra prima
del lancio, deve entrare nella **prima settimana dopo**, non "quando c'è
tempo".

### N6 · Rimuovere `ChooseYourFiveView` dall'onboarding · P0 · XS
Una rimozione è una feature. `docs/PRODOTTO.md` §7 la chiama "il singolo
errore di prodotto più grave nel repo" e la motiva: una matricola al giorno 1
non conosce cinque persone. È ancora in `RootView.swift:25`. Con N1 esiste il
sostituto, quindi il taglio non lascia buchi.

### Candidati scartati (per memoria, così non tornano)

| Idea | Domanda che fallisce |
|---|---|
| Mappa / "chi è vicino ora" | §8: Halo mappa relazioni, non posizioni |
| Streak, contatori, badge | §8: niente metriche pubbliche |
| Chat di gruppo del Ring | §8: WhatsApp esiste e ha vinto |
| Discovery pubblica | §3: rompe il moat |
| Halo+ / paywall / Stripe Events | §8: congelato fino a prova di ritenzione |
| Verifica OTP campus (§2.1) | resta P1: importante per la promessa, ma non blocca il funnel — vedi §5 |

---

## 5 · Sequenza consigliata (~3 settimane)

**W1 (7-13 ago) — sbloccare la distribuzione.** A6 avviato il primo giorno
(tempi morti), poi A1, A4, A5, B5, N6. Sono tutti corti: la settimana serve a
rendere l'app *caricabile*, non bella.

**W2 (14-20 ago) — il loop.** B1 (N1) e B2 (+N4) in parallelo, A2 e A3 in
coda. Fine settimana: il test decisivo del piano — da un messaggio WhatsApp su
un telefono senza app, essere Inner di chi ha invitato in meno di un minuto.

**W3 (21-27 ago) — push e beta.** B3 ridotto a invito + vibe, build
TestFlight, smoke test su device reale, founder circles reclutati.
N2, N3, N5 sono la coda immediata post-lancio, in quest'ordine.

**Cosa non entra, esplicitamente:** i 10 PR di polish aperti, Stripe
Events/Clubs, Memory/Halo+, Discovery, OTP campus (P1: al lancio restano
codici per-circle ruotati, con il codice pubblico bruciato disattivato — la
promessa di verifica resta più debole e va detta, non nascosta).

---

## 6 · Come si capisce entro 48h se ha funzionato

Il funnel è già strumentato: basta guardarlo nell'ordine giusto.

```
signup → ring_joined → ≥2 follow reciproci → vibe_set → reazione/reply ricevuta → ritorno D+1
```

Il gate vero non è il numero di download: è **quante persone superano il terzo
passaggio**. Se `ring_joined` è alto e i follow reciproci sono bassi, il
problema è N1 e si vede subito. Se i reciproci reggono ma non c'è ritorno a
D+1, il problema è push/reply (B3, N5) — e allora N2 e N3 diventano la
priorità della settimana dopo, non della roadmap generica.
