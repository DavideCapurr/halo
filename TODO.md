# Halo — Strada al lancio Bocconi

Checklist viva orientata a **un obiettivo solo: distribuire Halo a Bocconi con
successo**. Gli item sono sequenziati e marcati per criticità di lancio, non
per fase tecnica. Per lo storico completo e le scelte prese vedi `PLAN.md`.

> **Piano operativo completo (audit 2026-07-05)**:
> `docs/launch/PIANO-LANCIO-BOCCONI.md` — fasi, date, criteri di
> accettazione e triage. Questa checklist ne è il riassunto di stato.
>
> **Priorità aggiornate (audit codice 2026-08-06)**:
> `docs/launch/FEATURE-LANCIO.md` — cosa serve davvero al lancio, cosa taglia,
> e le feature nuove (roster di co-presenza, richiamo del giorno dopo, widget
> interattivo). Se i due file divergono, vince quello.

**Stato**: `[ ]` da fare · `[x]` fatto · `[~]` in corso · `[!]` bloccato
**Priorità**: 🚀 blocker di lancio · ⭐ alto impatto sul successo · 🔧 dopo il lancio

**Definition of done**: una matricola Bocconi scarica l'app, verifica
`@studbocconi.it`, entra in un Founder/Event Ring durante l'orientation week,
manda la prima vibe — e noi lo vediamo nel funnel.

---

## 0. Distribuzione — senza questo non si lancia 🚀
*(runbook eseguibile: `docs/launch/RUNBOOK.md`. Gli item con account
Apple/device sono manuali per natura: il repo prepara tutto lo scaffolding.)*

- [ ] Apple Developer account + App ID, capabilities (Sign in with Apple,
      App Groups, Push), provisioning — **manuale**, passi in `RUNBOOK.md §2`
      (entitlements Apple Sign-in/App Group già in repo; snippet Push pronto)
- [x] Build config di produzione: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
      `APP_GROUP_ID`, `HALO_URL_SCHEME` per app **e** widget
      — centralizzati in `Config/*.xcconfig` (single source `Shared.xcconfig`
      condivisa app+widget via `baseConfigurationReference`); risolti i
      placeholder `REPLACE_ME` del widget
- [ ] Prodotto StoreKit `app.halo.plus.monthly` creato in App Store Connect
      — **manuale**, campi esatti in `RUNBOOK.md §3` (config locale già in
      `HaloPlus.storekit`)
- [~] Supabase **prod** deployato: migrations + edge function
      (`waitlist-signup`, `apple-storekit-*`, `stripe-*`, `purge-expired`),
      secrets configurati — **scriptato**: `scripts/deploy-supabase-prod.sh`
      + `supabase/.env.prod.example`; resta da eseguire con le credenziali prod
- [ ] Build su **TestFlight** + privacy nutrition labels / review prep
      — **manuale**, checklist in `RUNBOOK.md §5`
- [ ] Smoke test end-to-end su device reale (auth → verify → ring → vibe)
      — **manuale**, checklist in `RUNBOOK.md §6`
- [ ] **App icon + `Assets.xcassets`** — oggi non esiste alcun asset catalog:
      l'upload su ASC fallisce senza icona (piano §0.1)
- [ ] **Cancellazione account in-app** — richiesta da App Review 5.1.1(v):
      edge function `delete-account` + voce in ProfileView (piano §0.2)
- [ ] **Privacy policy + termini + regole contenuti** — URL obbligatori per
      App Store e review UGC; pagine su `web/landing/` (piano §0.3)
- [ ] **Deployment target**: app a iOS 26.0 vs progetto/README 17.0 — portare
      a 17.0 (i fallback `#available` esistono già) o decidere (piano §0.4)

## 0-bis. Loop sociale — senza questo il lancio non tiene 🚀
*(dettaglio e criteri di accettazione: piano §1)*

- [ ] **Push notifications MVP**: invito Inner ricevuto, vibe di un Inner,
      reaction/reply — APNs + `device_tokens` + edge function (piano §1.1)
- [ ] **Invito https + universal links**: link cliccabile da WhatsApp che
      funziona anche senza app installata; inviti "aperti" per non iscritti
      (piano §1.2)
- [ ] **Reply 1:1 effimera** sul Moment/vibe, visibile solo all'autore
      (piano §1.3)
- [ ] **QR orientation → funnel https** (oggi `halo://` = vicolo cieco senza
      app installata) e rigenerare i PNG stampa (piano §1.4)
- [ ] **Landing**: `data-endpoint` waitlist collegato a prod (oggi i signup
      muoiono nel localStorage) + fix overflow mobile (piano §2.2)
- [ ] **Verifica @studbocconi.it con OTP email**: il founder code condiviso è
      committato nel repo pubblico → ruotare e passare a codici per-circle
      (piano §2.1)

## 1. Cold-start Bocconi — il successo si gioca qui ⭐
*(la strumentazione c'è, manca l'esecuzione)*

- [ ] Reclutare i **20 Founder Circle** — `docs/growth/founder-circles-tracker.csv`
      è un template vuoto (tutti gli slot `status=target`, lead vuoti)
- [ ] QR Event Ring stampati/posizionati per l'**orientation week**
      (seed `bocconi-orientation-week` già pronto)
- [ ] Verificare end-to-end il path **`@studbocconi.it`** su prod
- [ ] Conversione **waitlist → invito** attiva e testata

## 2. Misurazione del lancio (Fase E) — senza non sai se funziona ⭐
- [x] Migration tabella eventi (`analytics_events` + RLS)
- [x] `AnalyticsService.track(_:)`
- [x] Strumentare: `signup`, `invite_sent`, `invite_accepted`, `vibe_set`,
      `moment_created`, `ring_joined`, `move_closer`
- [x] Funnel attivazione → target **50% verified → activated**

---

## 3. Monetizzazione — può seguire il lancio 🔧
*(StoreKit Halo+ è già implementato; Events/Clubs usano Stripe via Edge Functions)*

- [x] UI checkout **Halo Events** (4.99 / 29 / 79-99) →
      `stripe-create-checkout-session`
- [x] **Halo Clubs** dashboard/billing (49-149/m)
- [x] Accesso a `stripe-customer-portal` dal profilo

## 4. Qualità & polish 🔧
- [ ] Test sui service principali (Posts, Follows, Vibes, Invites)
      — oggi solo `FriendshipTierTests` e `PostLifespanTests`
- [ ] Riallineare `PLAN.md` alle checkbox reali (es. StoreKit Halo+ è fatto
      ma segnato `[ ]` in Fase D)

## 5. Bloccato da asset/licenze esterni 🔧
- [!] Font **Satoshi** ufficiale — mapping già nei token, serve il bundle
      `.otf` licenziato (oggi fallback **Inter**, accettabile per il lancio)
- [!] **12 step intermedi** della mono ramp SWARM ufficiali
