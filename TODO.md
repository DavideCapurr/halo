# Halo — Lavoro residuo

Checklist viva del **solo lavoro aperto** per chiudere Halo. Per lo storico
completo e le scelte prese vedi `PLAN.md`; questo file traccia solo cosa manca.

**Stato**: `[ ]` da fare · `[x]` fatto · `[~]` in corso · `[!]` bloccato

---

## A. Codice nostro (nessun blocco esterno)

### Analytics & misurazione (Fase E) — 0%
- [ ] Migration tabella eventi (`analytics_events` + RLS)
- [ ] Helper client `AnalyticsService.track(_:)`
- [ ] Strumentare gli eventi: `signup`, `invite_sent`, `invite_accepted`,
      `vibe_set`, `moment_created`, `ring_joined`, `move_closer`
- [ ] Query/vista funnel attivazione → target **50% verified → activated**

### Stripe in app (Fase D) — backend già pronto, manca la UI
- [ ] UI checkout **Halo Events** (4.99 / 29 / 79-99) →
      chiama `stripe-create-checkout-session`
- [ ] **Halo Clubs** dashboard/billing (49-149/m)
- [ ] Accesso a `stripe-customer-portal` dal profilo

### Qualità
- [ ] Test sui service principali (Posts, Follows, Vibes, Invites)
      — oggi solo `FriendshipTierTests` e `PostLifespanTests`
- [ ] Riallineare `PLAN.md` alle checkbox reali (es. StoreKit Halo+ è fatto
      ma segnato `[ ]` in Fase D)

---

## B. Bloccato da asset/licenze esterni

- [!] Font **Satoshi** ufficiale — mapping già nei token, serve solo il
      bundle `.otf` licenziato (oggi fallback **Inter**)
- [!] **12 step intermedi** della mono ramp SWARM ufficiali

---

## C. "Il resto" — esecuzione, non codice

- [ ] Reclutare i **20 Founder Circle** — `docs/growth/founder-circles-tracker.csv`
      è ancora un template vuoto (tutti gli slot `status=target`, lead vuoti)
- [ ] Decisione prodotto: **billing Stripe oltre StoreKit** per Events/Clubs
      (PLAN.md, gap prodotto)
