# Halo — Piano di sviluppo

Roadmap canonica: Fase A-E qui sotto. Aggiornare stato task man mano.

**Stato**: `[ ]` da fare · `[x]` fatto · `[~]` in corso · `[!]` bloccato

---

## Stato corrente

**Fase attiva: validazione della tesi** (`docs/PRODOTTO.md` §10).

Il prossimo deliverable non e codice: e capire se il problema esiste. Vedi
`docs/PRODOTTO.md` per la tesi e `docs/DESIGN.md` §6 per come si verifica la
direzione visiva insieme alle conversazioni.

**Fase A e chiusa, non completata.** L'ereditarieta SWARM e stata rimossa dai
vincoli di Halo: SWARM e un linguaggio operator, Halo e consumer-social, e la
riconoscibilita cross-prodotto non esiste finche non ci sono utenti. La
direzione canonica e ora `docs/DESIGN.md`. I brief SWARM sono in
`docs/archive/`.

## Gap vs HALO PDF

### Design - direzione canonica: `docs/DESIGN.md`

I tre item bloccati di Fase A sono chiusi **senza oggetto**: con R4 (nessun
accent di brand) e R3 (un font solo) non servono ne la mono ramp a 14 step, ne
i file Satoshi ufficiali, ne il mapping stati<->SWARM.

Applicato al layer token: valori cambiati mantenendo ogni simbolo, cosi le ~24
superfici che consumano i token hanno ereditato la direzione senza refactor di
massa.

- [x] Spacing, easing e type scale canonici. Radii portati da 6/4/2 (operator)
      a 20/16/12 (`docs/DESIGN.md` R2).
- [x] R4 — nessun accent di brand: bronze e i tre alias SWARM risolvono a ink
      neutro. `SwarmHaloTierState` esprime la distanza con l'opacita dell'ink,
      non con una tinta, cosi la tinta resta libera di significare una cosa
      sola: qualcuno c'e.
- [x] R2 — ground `#0B0C0E` al posto del nero puro; ink bianco al posto del
      paper-cream. Il nero puro resta per ombre, scrim e il vuoto `farRest`.
- [x] R3 — una famiglia sola: `HaloType` risolve tutto al system face,
      `SwarmHaloFont` rimosso. Niente piu dipendenza da Satoshi licenziato ne
      rischio di fallback silenzioso su un PostScript name mancante.
- [x] R5 — widget allineato: la palette privata aveva ancora lime/purple/magenta
      SWARM. Ora ink neutro su ground, colore solo dai mood.
- [ ] Rimuovere i `.ttf` in `HaloApp/Resources/Fonts/` (~2,4 MB) e le voci
      `UIAppFonts` in Info.plist: non piu referenziati, ma tocca il progetto
      Xcode.
- [ ] Migrare i call site che usano ancora `bronze`/`bronzeSoft`/`bronzeGlow`
      (~20) a ink o a un mood reale, poi cancellare i token deprecati.
- [ ] Verificare su device: contrasto del nuovo ink, e che le bolle mood
      leggano ancora bene sul ground piu chiaro.

### Prodotto - HALO PDF da costruire sopra

- [x] Post "easy" effimeri (3h, low-stakes): `PostLifespan` in `HaloShared`,
      `PostsService.post(lifespan:)`, quick-compose `EasyComposeView` con tab
      dedicata. Riduce la frizione del postare ("non resta lì per sempre").
      Wiring feed/decay sui post easy resta da fare quando il Pulse passa da
      seed a dati live.
- [x] Rings: Event / Club / Course / Founder in DB e UI.
- [x] Inner Invite formale con deep link: migration `invites` + RLS,
      `InvitesService`, sheet creazione da HaloSpace e accettazione
      `halo://invite/{token}` con copy "ti ha messo nel suo Inner".
- [x] Memory archive Halo+.
- [x] Verifica Bocconi `@studbocconi.it` + founder invite code path:
      migration `campuses`/`campus_verifications`, validazione RLS lato DB,
      `CampusVerificationService` e `BocconiVerifyView` da profilo.
- [x] Report/block safety MVP: migration `reports` + `blocks` con RLS,
      `ReportsService`, sheet da HaloSpace e filtro Home sui profili bloccati.
- [ ] Halo Events / Halo Clubs con billing Stripe oltre StoreKit.
- [x] Welcome / Manifesto + Choose-your-5 onboarding.

## Roadmap operativa A-E

### Fase A - CHIUSA (adozione SWARM design, abbandonata)

Fase chiusa senza completamento il 6 agosto 2026. Motivo in `docs/DESIGN.md`
§2: il vincolo "Halo eredita da SWARM" era dichiarato non negoziabile ed era
la causa per cui quattro fonti in conflitto tenevano fermo il design system.
Rimosso il vincolo, gli item bloccati perdono oggetto invece di sbloccarsi.

Cosa sopravvive: spacing 4/8, easing, disciplina anti-saturazione, sweep voce,
lint hex -> token. Sono igiene, non identita.

Cosa e stato abbandonato: palette mono 14 step, 4 famiglie di font, i tre
activation color, il mapping stati<->SWARM.

Il lavoro visivo residuo vive in "Design - direzione canonica" sopra.

### Fase B - Gap prodotto HALO (3-4 settimane)

- [x] Migrations: `rings`, `ring_members`,
      `event_checkins`, `subscriptions`, `club_billing` + RLS.
- [x] Servizi: `RingsService`.
- [x] Schermate: `WelcomeManifestoView`, `ChooseYourFiveView`,
      `EventRingView` (QR scan + join token),
      `ClubRingView`, `MemoryArchiveView`.
- [~] Deep link `halo://invite/{token}` cablato per accettazione Inner.
      Push notifications: nuovo Moment, ring in scadenza.

### Fase C - Cold-start Bocconi (parallela a B)

- [x] Landing web statica + waitlist:
      `web/landing`, tabella `waitlist_signups`,
      function `waitlist-signup`.
- [x] Reclutare offline 20 Founder Circles:
      kit operativo + tracker 20 slot in `docs/growth/`,
      tabella `founder_circle_recruits`.
- [x] Verifica `@studbocconi.it` + `founder_invite` code path.
- [x] QR Event Ring per orientation week:
      QR statico, seed `bocconi-orientation-week`,
      quick action in `EventRingView`.

### Fase D - Monetizzazione (mese 2)

- [ ] Halo+ student EUR 2.99/m via StoreKit subscription products.
- [ ] Halo Events checkout Stripe (4.99 / 29 / 79-99).
- [ ] Halo Clubs dashboard (49-149/m).

### Fase E - Misurazione

- [ ] Analytics events: `signup`, `invite_sent`, `invite_accepted`,
      `vibe_set`, `moment_created`, `ring_joined`, `move_closer`.
- [ ] Funnel attivazione fino al target 50% verified -> activated.

---

## Inventario implementativo precedente

## Visione prodotto (decisioni prese)

- Feed **persona-centrico**, non post-centrico (unità = momento di una persona)
- **Nessun algoritmo**: l'ordine del feed riflette i tier assegnati dall'utente
- Orbital field = solo **follow mutuali** (entrambe le parti si seguono)
- Follow asimmetrici (celeb, account pubblici) → **catena di asteroidi** oltre l'ultimo ring
- **Vibe = presenza minima**: puoi essere nel feed degli altri senza postare nulla
- **Default Inner**: il compose parte sempre col tier più ristretto (anti-cringe)
- **Nessuna metrica pubblica**: zero like count, zero follower count, zero streak
- Scroll infinito **tier-sorted** (Inner prima, poi Close, Orbit, Nebula)
- App anti-cringe GenZ: vibe-first, foto-last, audience piccolo e noto

---

## Fase 1 — Backend & dati feed

### PostsService
- [x] `feedPosts()` — query home feed su tutti i follow, ordinata `tier_rank DESC, created_at DESC`
- [x] Implementare `post(kind:mediaPath:caption:mood:minTier:)` (era TODO step 6)
- [x] Implementare `delete(id:)` (era TODO step 6)
- [x] Implementare `posts(forUser:)` (era TODO step 9)
- [x] Default `minTier` da `orbit` → `inner` in tutta la app

### AuthService
- [x] Sign in with Apple (era TODO step 4)
- [x] Sign out
- [x] `currentUserId()`

### ProfilesService
- [x] `currentProfile()` (era TODO step 5)
- [x] `update(_:)` (era TODO step 5)
- [x] `search(handle:)` (era TODO step 7)
- [x] `profile(id:)` (era TODO step 7)

### FollowsService
- [x] `follow(_:)` (era TODO step 7)
- [x] `unfollow(_:)` (era TODO step 7)
- [x] `proposeTier(forTier:followeeId:)` (era TODO step 7)
- [x] `acceptProposedTier(followerId:)` (era TODO step 8)
- [x] `declineProposedTier(followerId:)` (era TODO step 8)
- [x] `myFollows()` (era TODO step 8)
- [x] `isMutual(userId:)` → Bool — usato da orbital field per filtrare

### VibesService
- [x] `setCurrent(mood:colorHex:note:)` (era TODO step 5)
- [x] `current(userId:)` (era TODO step 5)
- [x] `currentVibes(userIds:)` (era TODO step 8)

### ReactionsService
- [x] `react(postId:kind:)` (era TODO step 10)
- [x] `unreact(postId:kind:)` (era TODO step 10)
- [x] `reactions(postId:viewerTier:)` (era TODO step 10)

### StorageService
- [x] `uploadAvatar(data:contentType:)` (era TODO step 5)
- [x] `uploadPostMedia(data:contentType:)` (era TODO step 6)
- [x] `signedURL(path:bucket:ttlSeconds:)` (era TODO step 5)

### HomeViewModel
- [x] `load()` — combina follows + profiles + vibes + subscribe realtime (era TODO step 8)
- [x] Separare follow mutuali da follow asimmetrici
- [x] `feedItems: [MomentItem]` — dati per il Pulse feed

### DB — Supabase
- [x] Migration per indice `follows` mutualità (ottimizzazione query mutual check)
- [x] Edge function `realtime-feed` se necessario per live reactions
      *(non necessaria: il subscribe è gestito client-side in `FeedRealtime.swift` via `RealtimeChannelV2` su INSERT di halo_posts/vibes/reactions, sotto RLS)*

---

## Fase 2 — Orbital field: zoom + bolle vive + asteroidi

### Zoom system
- [x] `ZoomLevel` enum: `.innerOnly`, `.innerClose`, `.full`, `.asteroids`
- [x] `@State private var zoomLevel: ZoomLevel` in `OrbitalFieldView`
- [x] `FriendshipTier.ringRadius(at: ZoomLevel)` — funzione, non costante
- [x] `FriendshipTier.bubbleSize(at: ZoomLevel)` — scala col zoom, Inner cresce di più
- [x] Pinch gesture (`MagnificationGesture`) per zoom in/out
- [x] Slider verticale laterale auto-hide (scompare dopo 2s di inattività)
- [x] Animazione transition tra zoom levels
- [x] Nascondere tier fuori viewport (no render inutile)

### Bolle vive
- [x] Tinta bubble = `MoodPalette.auraColor(person.vibe.mood)` se vibe attiva, altrimenti neutro
- [x] Glow decay: intensità del glow proporzionale a `(72h - timeSinceLastPost) / 72h`
- [x] Indicatore "Adesso" su bubble se ha postato negli ultimi 30 min (puntino luminoso)
- [x] Anello pulsante se vibe attiva (TimelineView animation già vista in VibeSetterView)
- [x] `SelfCenterView` mostra la propria vibe color

### Filtro mutualità
- [x] `OrbitalFieldView` filtra `people` in input: mostra solo follow mutuali
- [x] Follow asimmetrici passati a `AsteroidBeltView` (nuovo componente)

### AsteroidBeltView (nuovo)
- [x] Componente separato, oltre il ring Nebula
- [x] Bubble piccole (~24px), non strutturate, con drift animato lento
- [x] Visibile solo a `zoomLevel == .asteroids`
- [x] Pan orizzontale per esplorare (può essere lunga)
- [x] Tap → HaloSpace della persona
- [x] Raggruppamento opzionale per categorie (artisti, brand, etc.)

---

## Fase 3 — Pulse Feed (feed di momenti)

### Struttura
- [x] `PulseFeedView` — view principale, scroll verticale
- [x] `FeedViewModel` — `@Observable`, carica `feedPosts()` + vibes
- [x] `MomentCard` — unità base del feed (vedi spec sotto)
- [x] `PresenceBar` — strip orizzontale in alto con vibe attive, tier-sorted
- [x] Sezioni visive per tier (header leggero: "Inner & Close" / "Orbit" / "Nebula")
- [x] Sezione "Adesso" in testa se ci sono post < 30 min

### MomentCard
- [x] Portrait con aura mood-color pulsante (usa `SelfCenterView` o nuovo)
- [x] Nome + tier badge + timestamp
- [x] Vibe note (se attiva): mood chip + nota testuale
- [x] Ultimo post dentro la card (foto / testo / audio) — opzionale, se c'è
- [x] Decay ring visibile intorno al post (anello che si svuota nelle 72h)
- [x] Reazioni: count per tier Orbit+, chi ha reagito per Inner/Close
- [x] Card senza post = valida (solo portrait + vibe) — presenza pura

### Dinamismo
- [x] Realtime Supabase subscribe per nuovi post/vibe nel feed
- [x] Animazione entrata nuova card in sezione "Adesso"
- [x] Ping animato per reazione live
- [x] Sfondo deep space prende leggera tinta dal mood dominante delle card visibili (`withAnimation`)
- [x] Card che scadono tra < 2h: bordo con colore caldo (warning visivo)

### Integrazione Home
- [x] `HomeView` ottiene tab/switch tra OrbitalField e PulseFeed
- [x] Transizione fluida tra i due (no tab bar, gesto swipe o pulsante?)

---

## Fase 4 — Compose vibe-first

### Flow nuovo
- [x] Rifare `ComposePostView` come `VibeFirstComposeView`
- [x] Step 1: mood chip selector (obbligatorio, anti-cringe: solo un colore)
- [x] Step 2: nota testuale 60ch (opzionale, skip esplicito)
- [x] Step 3: "Vuoi aggiungere un momento?" → [Foto] [Testo] [Audio] [Salta]
- [x] Step 4: tier selector — mostra **numero reale** ("condividi con i tuoi 4 Inner")
- [x] CTA: "Manda" (non "Pubblica", non "Posta")

### Accesso rapido
- [x] Long-press su `SelfCenterView` → apre `VibeFirstComposeView`
- [x] Bottom bar: pulsante compose porta a vibe-first (non direttamente alla camera)

### Tier selector anti-cringe
- [x] Mostra: `●Inner · 4 persone` / `●Close · 12 persone` / etc.
- [x] Default selezionato = Inner
- [x] Ogni tap più largo mostra warning soft ("anche 12 persone in più lo vedranno")

### Audio
- [x] `AudioRecorderView` (già esiste stub) — completare
- [x] Max durata: 60 secondi
- [x] Waveform visiva durante registrazione
- [x] Playback inline nella card

---

## Fase 5 — HaloSpace (profilo per-persona)

- [x] `HaloSpaceView` completo — griglia/lista post non scaduti dell'utente
- [x] `PostCardView` con media (foto/testo/audio), caption, mood tag, decay indicator
- [x] `ReactionBarView` — 6 glyph (`ReactionGlyph`), stato selezionato, count/actor tier-aware
- [x] Swipe left/right tra persone dello stesso tier
- [x] Header: portrait grande + display name + handle + tier badge + vibe attiva
- [x] Sezione "HaloSpace vuoto" se nessun post attivo (stato empty con mood)

---

## Fase 6 — Auth & onboarding

- [x] `SignInView` — Sign in with Apple + email OTP fallback
- [x] `OnboardingView` — scegli handle, display name, upload avatar
- [x] `InitialInnerCircleView` — aggiungi primi 1-5 Inner (da contatti o handle)
- [x] `RootView` — routing auth → onboarding → home
- [x] `AppState` — stato globale sessione (già stub, da completare)

---

## Fase 7 — Prodotto pubblico: celeb & profili pubblici

- [x] `is_public` flag su `profiles` (migration DB)
- [x] Profili pubblici visibili in search senza follow
- [x] Follow di profilo pubblico = asimmetrico → catena asteroidi
- [x] Post con `min_tier = nebula` da profilo pubblico = visibile a chiunque segua
- [x] Discovery/search per account pubblici

---

## Fase 8 — Widget

- [x] Completare `Provider.swift` — carica `WidgetSnapshot` da app group
- [x] `LockscreenWidget` con orbital mini-field (bolle live con mood tint)
- [x] `StandByWidget` per StandBy mode iPhone
- [x] Aggiornamento snapshot quando arriva nuova vibe/post (background refresh)

---

## Fase 9 — Copy, design, polish

### Lessico anti-cringe (sweep su tutta la app)
- [x] "Posta" / "Pubblica" → "Manda" / "Condividi"
- [x] "Followers" / "Following" → "Halo" / "Cerchi"
- [x] "Story" → "Vibe" / "Momento"
- [x] "Feed" → "Pulse" / "Presenza"
- [x] "Profilo" → "HaloSpace"
- [x] "Like" → rimosso, solo reazioni glyph

### Nessuna metrica pubblica
- [x] Verificare: zero `follower count` visibile in UI
- [x] Verificare: zero `like count` / `view count` visibili
- [x] Verificare: zero streak, zero badge, zero gamification

### Animazioni & polish
- [x] Micro-drift sulle card del feed (subliminale)
- [x] Transizioni fluide tra orbital field e pulse feed
- [x] Haptic coerenti con i tier (Inner = `.heavy`, Close = `.medium`, Orbit = `.light`)
- [x] Dark mode only (già impostato, verificare consistenza)

---

## Dipendenze tecniche

| Cosa | Dipende da |
|------|-----------|
| PulseFeed | PostsService.feedPosts(), FeedViewModel, MomentCard |
| AsteroidBelt | FollowsService.isMutual(), OrbitalFieldView refactor |
| MomentCard | Vibe attiva, ultimo post, ReactionBarView |
| Compose vibe-first | VibesService.setCurrent(), PostsService.post() |
| Bolle vive | VibesService.currentVibes(), PostsService.posts() |
| Zoom | OrbitalFieldView refactor ZoomLevel |
| Auth | Tutto il resto della app in prod |

---

## Ordine di implementazione consigliato

```
1. PostsService.feedPosts() + VibesService stubs → base dati
2. MomentCard + PulseFeedView (con dati seed) → feed visibile
3. PresenceBar + sezione "Adesso" → dinamismo base
4. Orbital field bolle vive (mood tint + glow decay)
5. Zoom system + AsteroidBeltView
6. VibeFirstComposeView (flow anti-cringe)
7. HaloSpaceView completo + ReactionBarView
8. Auth + Onboarding
9. Widget
10. Copy sweep + polish finale
```
