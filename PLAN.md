# Halo — Piano di sviluppo

Documento di riferimento per l'implementazione. Aggiornare stato task man mano.

**Stato**: `[ ]` da fare · `[x]` fatto · `[~]` in corso · `[!]` bloccato

---

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
- [ ] Edge function `realtime-feed` se necessario per live reactions

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
- [ ] Step 3: "Vuoi aggiungere un momento?" → [Foto] [Testo] [Audio] [Salta]
- [ ] Step 4: tier selector — mostra **numero reale** ("condividi con i tuoi 4 Inner")
- [ ] CTA: "Manda" (non "Pubblica", non "Posta")

### Accesso rapido
- [ ] Long-press su `SelfCenterView` → apre `VibeFirstComposeView`
- [ ] Bottom bar: pulsante compose porta a vibe-first (non direttamente alla camera)

### Tier selector anti-cringe
- [ ] Mostra: `●Inner · 4 persone` / `●Close · 12 persone` / etc.
- [ ] Default selezionato = Inner
- [ ] Ogni tap più largo mostra warning soft ("anche 12 persone in più lo vedranno")

### Audio
- [ ] `AudioRecorderView` (già esiste stub) — completare
- [ ] Max durata: 60 secondi
- [ ] Waveform visiva durante registrazione
- [ ] Playback inline nella card

---

## Fase 5 — HaloSpace (profilo per-persona)

- [ ] `HaloSpaceView` completo — griglia/lista post non scaduti dell'utente
- [ ] `PostCardView` con media (foto/testo/audio), caption, mood tag, decay indicator
- [ ] `ReactionBarView` — 6 glyph (`ReactionGlyph`), stato selezionato, count/actor tier-aware
- [ ] Swipe left/right tra persone dello stesso tier
- [ ] Header: portrait grande + display name + handle + tier badge + vibe attiva
- [ ] Sezione "HaloSpace vuoto" se nessun post attivo (stato empty con mood)

---

## Fase 6 — Auth & onboarding

- [ ] `SignInView` — Sign in with Apple + email OTP fallback
- [ ] `OnboardingView` — scegli handle, display name, upload avatar
- [ ] `InitialInnerCircleView` — aggiungi primi 1-5 Inner (da contatti o handle)
- [ ] `RootView` — routing auth → onboarding → home
- [ ] `AppState` — stato globale sessione (già stub, da completare)

---

## Fase 7 — Prodotto pubblico: celeb & profili pubblici

- [ ] `is_public` flag su `profiles` (migration DB)
- [ ] Profili pubblici visibili in search senza follow
- [ ] Follow di profilo pubblico = asimmetrico → catena asteroidi
- [ ] Post con `min_tier = nebula` da profilo pubblico = visibile a chiunque segua
- [ ] Discovery/search per account pubblici

---

## Fase 8 — Widget

- [ ] Completare `Provider.swift` — carica `WidgetSnapshot` da app group
- [ ] `LockscreenWidget` con orbital mini-field (bolle live con mood tint)
- [ ] `StandByWidget` per StandBy mode iPhone
- [ ] Aggiornamento snapshot quando arriva nuova vibe/post (background refresh)

---

## Fase 9 — Copy, design, polish

### Lessico anti-cringe (sweep su tutta la app)
- [ ] "Posta" / "Pubblica" → "Manda" / "Condividi"
- [ ] "Followers" / "Following" → "Halo" / "Cerchi"
- [ ] "Story" → "Vibe" / "Momento"
- [ ] "Feed" → "Pulse" / "Presenza"
- [ ] "Profilo" → "HaloSpace"
- [ ] "Like" → rimosso, solo reazioni glyph

### Nessuna metrica pubblica
- [ ] Verificare: zero `follower count` visibile in UI
- [ ] Verificare: zero `like count` / `view count` visibili
- [ ] Verificare: zero streak, zero badge, zero gamification

### Animazioni & polish
- [ ] Micro-drift sulle card del feed (subliminale)
- [ ] Transizioni fluide tra orbital field e pulse feed
- [ ] Haptic coerenti con i tier (Inner = `.heavy`, Close = `.medium`, Orbit = `.light`)
- [ ] Dark mode only (già impostato, verificare consistenza)

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
