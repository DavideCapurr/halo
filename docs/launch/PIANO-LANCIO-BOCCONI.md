# Piano di lancio Bocconi — sistemare tutto, in ordine

Piano operativo unico per arrivare all'orientation week con un prodotto che
può essere scaricato, attivato e usato. Sostituisce la lettura sparsa di
`TODO.md`/`PLAN.md` per le prossime 8 settimane: qui c'è **cosa**, **perché**,
**come** e **quando**, con criteri di accettazione verificabili.

Basato sull'audit del 2026-07-05 (verifica diretta del codice, non dei
documenti). Orizzonte: **~8 settimane** da oggi all'orientation week
(assunzione: ultima settimana di agosto — verificare la data esatta sul
calendario Bocconi e ricalibrare).

**Principio guida**: il lancio non fallisce per una feature mancante, fallisce
se due matricole non riescono a collegarsi in meno di un minuto da un
messaggio WhatsApp, o se l'app non arriva su TestFlight. Tutto il piano è
ordinato attorno a questi due rischi.

---

## Fase 0 — Blocker di distribuzione (W1: 6–12 lug)

Senza questi l'app non esiste su TestFlight. Nessuno è nel TODO attuale.

### 0.1 App icon + Assets.xcassets — `S`
Non esiste alcun asset catalog nel repo: `ASSETCATALOG_COMPILER_APPICON_NAME
= AppIcon` punta nel vuoto. L'upload su App Store Connect fallisce senza icona.
- Creare `HaloApp/Assets.xcassets` con AppIcon (1024px, single-size) coerente
  col brand app (anello bronzo su nero, wordmark serif). Aggiungerlo al pbxproj.
- Icona anche per il widget se si usa un catalogo separato.
- **Fatto quando**: `xcodebuild archive` produce un archivio con icona valida.

### 0.2 Cancellazione account in-app — `M`
Guideline 5.1.1(v): ogni app con registrazione deve permettere di eliminare
l'account. Oggi c'è solo sign out → rejection quasi certa.
- Edge function `delete-account` (service role): cancella storage
  (`halo-avatars/{uid}/`, `halo-media/{uid}/`), poi `auth.admin.deleteUser`
  (le FK `on delete cascade` già in schema puliscono profiles/posts/follows/…).
- Client: voce "Elimina account" in `ProfileView` → conferma esplicita →
  invoke function → `didSignOut()`.
- **Fatto quando**: un utente di test si elimina e non restano righe né file.

### 0.3 Privacy policy, termini, regole contenuti — `S/M`
Richiesti da App Store (URL obbligatorio) e dalle regole UGC (4.1): serve un
documento con regole dei contenuti + impegno di moderazione.
- Pagine statiche su `web/landing/` (`/privacy`, `/termini`, `/regole`).
- Link in app (ProfileView, footer sign-in) e nel `ReportUserSheet`.
- Decidere age rating (nota: età consenso digitale in Italia = 14).
- **Fatto quando**: gli URL esistono, sono linkati in app e pronti per i campi
  di App Store Connect.

### 0.4 Deployment target: decidere, non subire — `S`
Il target app è `iOS 26.0` ma tutto il codice Liquid Glass è già dietro
`#available(iOS 26.0, *)` con fallback: il floor a 26 sembra un incidente e
taglia chiunque non abbia aggiornato.
- Portare `IPHONEOS_DEPLOYMENT_TARGET` dell'app a 17.0 (come progetto, widget
  e README), smoke test visivo dei fallback non-glass su simulatore iOS 17/18.
- **Fatto quando**: build e UI verificate su iOS 17 e su iOS 26.

### 0.5 Supabase prod deployato — `S`
Lo script c'è (`scripts/deploy-supabase-prod.sh` + `.env.prod.example`): va
eseguito con le credenziali prod, incluse le nuove function di questo piano
man mano che nascono. Schedulare `purge-expired` via pg_cron.
- **Fatto quando**: migrations applicate, functions attive, secrets configurati,
  smoke test da app contro prod.

### 0.6 Account Apple Developer + capabilities — `manuale, avviare subito`
Pratica burocratica con tempi morti: avviarla in W1 anche se il codice non è
pronto. App ID `la.halo`, Sign in with Apple, App Groups, **Push Notifications**
(serve per la Fase 1), provisioning. Segue `RUNBOOK.md §2`.

---

## Fase 1 — Il loop sociale (W2–W4: 13 lug – 2 ago)

Il prodotto oggi ha la scenografia dell'intimità ma non i canali che la fanno
circolare: arrivare (inviti), essere avvisati (push), rispondere (reply).
Questa fase è il cuore del piano.

### 1.1 Push notifications MVP — `L` (la singola feature più importante)
Zero riferimenti ad APNs nel codebase. Senza push, l'effimeralità (vibe 24h,
easy 3h) garantisce orbite vuote e churn.
Scope minimo, in ordine di valore:
1. **Proposta/invito Inner ricevuto** — sblocca la catena di attivazione
   (oggi il destinatario non sa nemmeno che esiste una proposta).
2. **Vibe nuova di un Inner** ("X sta vibrando") — è il momento-prodotto.
3. Reazione/reply ricevuta sul proprio Moment.

Implementazione:
- Client: capability push, `UNUserNotificationCenter` (permesso chiesto DOPO
  il primo valore, es. alla prima vibe, non al primo avvio), registrazione
  token → tabella `device_tokens (user_id, token, platform, updated_at)` + RLS.
- Backend: edge function `push-send` (JWT ES256 con chiave `.p8` APNs);
  trigger/database-webhook su `invites`, `vibes`, `reactions` (e `replies`,
  vedi 1.3) che invocano la function. Fan-out limitato ai follower Inner/Close
  per le vibe (rispettando i tier — la RLS non copre APNs: filtrare nel worker).
- Preferenze minime: toggle on/off in ProfileView.
- **Fatto quando**: su device fisico, l'invito e la vibe di un Inner producono
  la notifica giusta, e nessuna notifica viola i tier.

### 1.2 Invito che funziona su WhatsApp: link https + universal links — `M/L`
Oggi il link è `halo://invite/…`: non cliccabile in chat, morto senza app
installata, e l'invito richiede che l'invitato sia **già iscritto**. La catena
va rovesciata: un link che chiunque può aprire.
- Universal links: entitlement Associated Domains + file AASA servito dal
  dominio della landing; routing `https://<dominio>/i/{token}` e
  `/r/{token}` (ring) in app accanto allo scheme `halo://`.
- Pagina web `/i/{token}`: se l'app è installata si apre direttamente; se no,
  bottone TestFlight/App Store + **codice breve visibile** da inserire in app
  ("hai un codice?") come deferred deep link a prova di studente.
- DB: permettere inviti "aperti" — `invites.invitee_id` nullable + claim al
  primo redeem post-signup (RLS: solo `pending`, un solo claim, scadenza).
- ShareLink in `InviteSheets`/`EventRingView` passa al link https con testo
  precompilato.
- **Fatto quando**: da un messaggio WhatsApp su un telefono senza app si
  arriva a essere Inner dell'invitante in < 1 minuto (il test decisivo).

### 1.3 Risposta 1:1 effimera ("sussurro") — `M`
Il concept promette intimità ma all'amico "lost" si può solo mandare un glifo:
la conversazione scappa su WhatsApp e Halo diventa una dashboard. Non serve
una chat: serve chiudere il loop.
- Tabella `replies (post_id, author_id, text ≤140, created_at, expires_at)`;
  RLS: INSERT se il viewer vede il post, SELECT **solo autore del post +
  autore della reply**. Scade col post.
- UI: campo di risposta in `MomentCard`/`HaloSpacePeekSheet`; le reply
  arrivano al proprietario del post (lista sotto il proprio Moment) + push.
- Niente thread, niente inbox globale: una reply è un sussurro, non un DM.
- **Fatto quando**: rispondo alla vibe di un Inner e lui la legge (e riceve
  push) senza uscire da Halo.

### 1.4 QR orientation week sul nuovo funnel — `S` (dipende da 1.2)
Il QR seedato punta a `halo://ring/join/bocconi-orientation-week`: scan senza
app installata = vicolo cieco, cioè il caso di *tutti* durante l'orientation.
- QR → `https://<dominio>/r/bocconi-orientation-week` → app se installata,
  altrimenti TestFlight + token visibile.
- Rigenerare i PNG in `web/landing/assets/` e il materiale stampa.
- **Fatto quando**: scan da telefono vergine → install → join ring, senza
  aiuto umano.

---

## Fase 2 — Fiducia e igiene (W4–W5: 27 lug – 9 ago)

### 2.1 Verifica @studbocconi.it vera (OTP email) — `M`
Oggi la "verifica" è un check del suffisso + codice condiviso
`BOCCONI-FOUNDERS-2026` **committato in un repo pubblico** (già bruciato).
La promessa "spazio verificato Bocconi" al lancio sarebbe vuota.
- Edge function `send-campus-otp` (Resend/SES: codice 6 cifre alla mail
  @studbocconi.it, hash+scadenza in tabella) + `verify-campus-otp`.
- `BocconiVerifyView` diventa two-step: email → codice ricevuto.
- Founder code: resta come *secondo* gate ma per-circle (20 codici distinti,
  `max_uses=5·x`), inseriti a mano in prod, **mai** in migration. Ruotare e
  disattivare il codice bruciato.
- **Fatto quando**: senza accesso alla casella non si supera la verifica; il
  vecchio codice è disattivato.

### 2.2 Landing: collegare e riparare — `S`
- `data-endpoint` → URL prod di `waitlist-signup` (oggi le iscrizioni muoiono
  nel localStorage del visitatore).
- Fix overflow mobile: a 430px il titolo hero e le CTA vengono tagliati
  (verificato con screenshot). Test 360/390/430px.
- Aggiungere link privacy/termini (da 0.3), e le route `/i/`, `/r/` + AASA
  (da 1.2).
- Allineamento brand: decisione consapevole — lime/magenta resta l'identità
  "campagna" (poster, QR, landing), bronzo/crema l'identità prodotto, ma
  wordmark e serif condivisi + screenshot reali dell'app in landing, così il
  passaggio QR→app non sembra cambiare prodotto.
- **Fatto quando**: form salva su `waitlist_signups` in prod; nessun clipping
  a 360px; link legali presenti.

### 2.3 Moderazione minima operativa — `S`
Report e block esistono, ma i report finiscono in una tabella che nessuno
legge. Per App Review (UGC) e per la realtà di un campus:
- Query salvate/vista admin su Supabase per i report aperti + impegno
  esplicito di gestione < 24h (scritto in `/regole`).
- In `ReportUserSheet`: link alle regole + conferma di presa in carico.
- **Fatto quando**: un report di prova è visibile in una vista dedicata e
  esiste una procedura scritta.

### 2.4 Robustezza feed e orbita — `S`
- `feedPosts()` senza `.limit()`: aggiungere `limit(200)` (scala lancio).
- Orbita: i cap di rendering (4 Inner / 9 Close / 8 Orbit) nascondono persone
  senza indicazione → chip "+N" per anello che apre la lista completa.
- **Fatto quando**: con 20 Close, tutti raggiungibili in ≤ 2 tap.

### 2.5 CI minima — `S/M`
Zero CI oggi. Bastano due job GitHub Actions:
- macOS runner: `swift test` su HaloShared + `xcodebuild build` senza firma.
- Linux runner: `supabase start && supabase db reset` per validare le
  migrations.
- **Fatto quando**: la PR rossa blocca il merge.

---

## Fase 3 — Beta, review, lancio (W5–W8: 3 – 30 ago)

### 3.1 TestFlight come canale di lancio (decisione strategica)
Raccomandazione: **l'orientation week gira su TestFlight public link**, non
sull'App Store.
- Beta review più leggera e veloce, 10k tester, iterazione quotidiana senza
  review completa — esattamente ciò che serve la settimana del lancio.
- Submission App Store in parallelo (senza gate sul lancio), con buffer per
  una probabile prima rejection.

### 3.2 Beta founder circles (W5–W6)
- Build su TestFlight + nutrition labels (`RUNBOOK.md §5`).
- Smoke test end-to-end su device reale: auth → OTP verify → ring → vibe →
  push → invito WhatsApp → reply (`RUNBOOK.md §6` esteso ai nuovi flussi).
- Reclutare i 20 Founder Circle (il tracker CSV è vuoto: è il collo di
  bottiglia umano, partire in W5) e usarli come beta tester: 100 persone
  reali prima dell'orientation.
- Monitorare da subito il funnel su `analytics_events`
  (signup → verified → ring_joined → vibe_set → invite_accepted),
  target 50% verified → activated.

### 3.3 Settimana di lancio (W8)
- QR stampati col funnel nuovo (1.4), posizionamento fisico, referenti per
  circle presenti agli eventi.
- Presidio quotidiano: report < 24h, crash/log, funnel giornaliero, fix via
  TestFlight.

---

## Cosa NON fare prima del lancio (tagli espliciti)

Energia già spesa da proteggere, ma che non deve rubare tempo alle fasi 0–3:
- **Stripe Events/Clubs**: il codice c'è, non attivarlo (e i Clubs con
  feature digitali in-app rischiano la 3.1.1 — rivalutare dopo).
- **Memory/Halo+ paywall**: lo StoreKit è pronto; il prodotto in ASC può
  aspettare settembre. Monetizzare prima del PMF non serve al lancio.
- **Discovery pubblica (celeb/brand)**: contraddice "your people, not your
  audience" e a Bocconi non ci sono account pubblici da scoprire. Nascondere
  la superficie per v1 (meno review surface, più coerenza).
- Font Satoshi licenziato, mono ramp SWARM, refactor di `HomeView` (1.6k
  righe): dopo il lancio.

## Triage se si va in ritardo

Non negoziabili (senza = non lanciare): 0.1, 0.2, 0.3, 0.5, 1.1 (almeno
notifica inviti), 1.2, 1.4, 2.2 (endpoint waitlist).
Comprimibili: 1.3 (reply può slittare alla settimana dopo il lancio — ma è la
retention), 2.1 (in extremis: codici per-circle segreti senza OTP, accettando
la promessa di verifica indebolita), 2.4, 2.5.

## Rischi residui

- **App Review**: UGC + social → probabile richiesta chiarimenti su
  moderazione. Mitigazione: 0.3 + 2.3 fatti bene, lancio su TestFlight (3.1).
- **Data orientation week**: tutto il calendario assume ~fine agosto.
  Verificare la data ufficiale in W1 e ricalibrare.
- **Push = infrastruttura nuova**: è l'item con più incognite (APNs, p8,
  webhook). Per questo è in W2, non in W6: il buffer serve lì.
- **Massa critica**: anche con tutto verde, il cold-start resta una scommessa
  di esecuzione umana (founder circles). Il piano la rende *possibile*, non
  garantita: il funnel (3.2) dice entro 48h dall'orientation se sta
  funzionando.
