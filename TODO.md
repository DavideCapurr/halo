# Halo — Strada al lancio Bocconi

Checklist viva orientata a **un obiettivo solo: distribuire Halo a Bocconi con
successo**. Gli item sono sequenziati e marcati per criticità di lancio, non
per fase tecnica. Per lo storico completo e le scelte prese vedi `PLAN.md`.

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

## 1. Cold-start Bocconi — il successo si gioca qui ⭐
*(la strumentazione c'è, manca l'esecuzione)*

- [ ] Reclutare i **20 Founder Circle** — `docs/growth/founder-circles-tracker.csv`
      è un template vuoto (tutti gli slot `status=target`, lead vuoti)
- [ ] QR Event Ring stampati/posizionati per l'**orientation week**
      (seed `bocconi-orientation-week` già pronto)
- [ ] Verificare end-to-end il path **`@studbocconi.it`** su prod
- [ ] Conversione **waitlist → invito** attiva e testata

## 2. Misurazione del lancio (Fase E) — senza non sai se funziona ⭐
- [ ] Migration tabella eventi (`analytics_events` + RLS)
- [ ] `AnalyticsService.track(_:)`
- [ ] Strumentare: `signup`, `invite_sent`, `invite_accepted`, `vibe_set`,
      `moment_created`, `ring_joined`, `move_closer`
- [ ] Funnel attivazione → target **50% verified → activated**

---

## 3. Monetizzazione — può seguire il lancio 🔧
*(StoreKit Halo+ è già implementato; il resto è backend-only)*

- [ ] UI checkout **Halo Events** (4.99 / 29 / 79-99) →
      `stripe-create-checkout-session`
- [ ] **Halo Clubs** dashboard/billing (49-149/m)
- [ ] Accesso a `stripe-customer-portal` dal profilo

## 4. Qualità & polish 🔧
- [ ] Test sui service principali (Posts, Follows, Vibes, Invites)
      — oggi solo `FriendshipTierTests` e `PostLifespanTests`
- [ ] Riallineare `PLAN.md` alle checkbox reali (es. StoreKit Halo+ è fatto
      ma segnato `[ ]` in Fase D)

## 5. Bloccato da asset/licenze esterni 🔧
- [!] Font **Satoshi** ufficiale — mapping già nei token, serve il bundle
      `.otf` licenziato (oggi fallback **Inter**, accettabile per il lancio)
- [!] **12 step intermedi** della mono ramp SWARM ufficiali
