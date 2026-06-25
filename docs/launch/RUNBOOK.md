# Halo — Launch runbook (Fase 0 · Distribuzione)

Esecuzione passo-passo della Fase 0 di `TODO.md`. Gli step **automatizzabili**
hanno un comando; quelli **manuali** (account Apple, App Store Connect, device
reale) hanno la checklist esatta. Definition of done: una matricola scarica
l'app, verifica `@studbocconi.it`, entra in un ring, manda la prima vibe.

Identificatori canonici:

| Cosa | Valore |
|------|--------|
| Bundle ID app | `la.halo` |
| Bundle ID widget | `la.halo.widget` |
| App Group | `group.app.halo.shared` |
| URL scheme | `halo` |
| StoreKit product | `app.halo.plus.monthly` (€2.99/m) |
| Subscription group | `HALO_PLUS` |
| Supabase prod ref | `gxzdasexwlfmxhimaxnd` |

---

## 1. Build config di produzione ✅ (in repo)

Centralizzata in `Config/*.xcconfig` (`Shared` → app + widget). Niente da fare
qui se non cambiare progetto Supabase: edita `Config/Shared.xcconfig`.

## 2. Apple Developer — App ID, capabilities, provisioning (manuale)

In [developer.apple.com](https://developer.apple.com/account) → Certificates,
Identifiers & Profiles:

1. **App Group**: crea `group.app.halo.shared` (Identifiers → App Groups).
2. **App ID** `la.halo` con capabilities:
   - Sign in with Apple
   - App Groups → `group.app.halo.shared`
   - **Push Notifications**
3. **App ID** `la.halo.widget` con capability App Groups → `group.app.halo.shared`.
4. Provisioning profiles (o lascia gestire a Xcode "Automatically manage signing"
   con `DEVELOPMENT_TEAM = 2MY3NF258J`, già impostato nei target).

> ⚠️ **Push**: l'entitlement Push **non** è ancora in `HaloApp.entitlements`
> apposta — aggiungerlo prima che l'App ID abbia la capability rompe la firma.
> Dopo aver abilitato Push sull'App ID, aggiungi a `HaloApp/HaloApp.entitlements`:
>
> ```xml
> <key>aps-environment</key>
> <string>development</string>   <!-- Xcode usa "production" in distribuzione -->
> ```

## 3. StoreKit product in App Store Connect (manuale)

La config locale è già in `HaloApp/Resources/HaloPlus.storekit` (per i test in
simulatore). In [App Store Connect](https://appstoreconnect.apple.com) replica
**esattamente** questi campi:

- Subscription Group: `Halo Plus`
- Product ID: `app.halo.plus.monthly`
- Reference name: `Halo Plus Monthly`
- Durata: 1 mese (`P1M`) · Prezzo: €2.99
- Display name: `Halo Plus` · Descrizione:
  "Memory privata, recap eventi, preset Vibe+ e skin leggere."

Genera poi la **In-App Purchase key** (Users and Access → Integrations) e usala
per i secret `APPLE_STOREKIT_*` (step 4).

## 4. Supabase prod — migrations + functions + secrets (automatizzato)

```bash
supabase login                                  # una tantum
cp supabase/.env.prod.example supabase/.env.prod   # poi riempi i secret
PROJECT_REF=gxzdasexwlfmxhimaxnd ./scripts/deploy-supabase-prod.sh
```

Lo script fa: `link` → `db push` (14 migrations) → deploy delle 7 edge function
(con `--no-verify-jwt` per webhook/endpoint pubblici) → `secrets set` da
`supabase/.env.prod`. Secret richiesti: vedi `supabase/.env.prod.example`
(Apple StoreKit, Stripe, landing origin, media bucket).

Configura inoltre nei provider esterni i webhook verso le function prod:
`…/functions/v1/stripe-webhook` e `…/functions/v1/apple-storekit-webhook`.

## 5. TestFlight + privacy (manuale)

1. In Xcode: scheme `HaloApp` → Any iOS Device → Product → Archive → Distribute →
   App Store Connect.
2. **Privacy nutrition labels** (App Store Connect → App Privacy). Dati raccolti:
   - Contatti/Identità: email (Sign in with Apple), handle.
   - Contenuti utente: foto, audio, testo dei post (effimeri).
   - Permessi runtime già dichiarati in `HaloApp/Info.plist`:
     `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
     `NSPhotoLibraryUsageDescription`.
3. Aggiungi i tester interni (Founder Circle) al gruppo TestFlight.

## 6. Smoke test e2e su device reale (manuale)

Su iPhone fisico, build Release, account `@studbocconi.it`:

- [ ] **Auth**: Sign in with Apple → onboarding (handle, display name, avatar).
- [ ] **Verify**: profilo → `BocconiVerifyView` → email `@studbocconi.it` → verde.
- [ ] **Ring**: scan QR `bocconi-orientation-week` → join Event Ring.
- [ ] **Vibe**: long-press SelfCenter → manda la prima vibe (mood + nota).
- [ ] **Widget**: aggiungi il lockscreen widget → mostra l'orbital mini-field.
- [ ] **Funnel**: l'evento compare nel funnel (Fase E, sezione 2 di TODO.md).
