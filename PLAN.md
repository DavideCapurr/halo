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
- [ ] `feedPosts()` — query home feed su tutti i follow, ordinata `tier_rank DESC, created_at DESC`
- [ ] Implementare `post(kind:mediaPath:caption:mood:minTier:)` (era TODO step 6)
- [ ] Implementare `delete(id:)` (era TODO step 6)
- [ ] Implementare `posts(forUser:)` (era TODO step 9)
- [ ] Default `minTier` da `orbit` → `inner` in tutta la app

### AuthService
- [ ] Sign in with Apple (era TODO step 4)
- [ ] Sign out
- [ ] `currentUserId()`

### ProfilesService
- [ ] `currentProfile()` (era TODO step 5)
- [ ] `update(_:)` (era TODO step 5)
- [ ] `search(handle:)` (era TODO step 7)
- [ ] `profile(id:)` (era TODO step 7)

### FollowsService
- [ ] `follow(_:)` (era TODO step 7)
- [ ] `unfollow(_:)` (era TODO step 7)
- [ ] `proposeTier(forTier:followeeId:)` (era TODO step 7)
- [ ] `acceptProposedTier(followerId:)` (era TODO step 8)
- [ ] `declineProposedTier(followerId:)` (era TODO step 8)
- [ ] `myFollows()` (era TODO step 8)
- [ ] `isMutual(userId:)` → Bool — usato da orbital field per filtrare

### VibesService
- [ ] `setCurrent(mood:colorHex:note:)` (era TODO step 5)
- [ ] `current(userId:)` (era TODO step 5)
- [ ] `currentVibes(userIds:)` (era TODO step 8)

### ReactionsService
- [ ] `react(postId:kind:)` (era TODO step 10)
- [ ] `unreact(postId:kind:)` (era TODO step 10)
- [ ] `reactions(postId:viewerTier:)` (era TODO step 10)

### StorageService
- [ ] `uploadAvatar(data:contentType:)` (era TODO step 5)
- [ ] `uploadPostMedia(data:contentType:)` (era TODO step 6)
- [ ] `signedURL(path:bucket:ttlSeconds:)` (era TODO step 5)

### HomeViewModel
- [ ] `load()` — combina follows + profiles + vibes + subscribe realtime (era TODO step 8)
- [ ] Separare follow mutuali da follow asimmetrici
- [ ] `feedItems: [MomentItem]` — dati per il Pulse feed

### DB — Supabase
- [ ] Migration per indice `follows` mutualità (ottimizzazione query mutual check)
- [ ] Edge function `realtime-feed` se necessario per live reactions

---

## Fase 2 — Orbital field: zoom + bolle vive + asteroidi

### Zoom system
- [ ] `ZoomLevel` enum: `.innerOnly`, `.innerClose`, `.full`, `.asteroids`
- [ ] `@State private var zoomLevel: ZoomLevel` in `OrbitalFieldView`
- [ ] `FriendshipTier.ringRadius(at: ZoomLevel)` — funzione, non costante
- [ ] `FriendshipTier.bubbleSize(at: ZoomLevel)` — scala col zoom, Inner cresce di più
- [ ] Pinch gesture (`MagnificationGesture`) per zoom in/out
- [ ] Slider verticale laterale auto-hide (scompare dopo 2s di inattività)
- [ ] Animazione transition tra zoom levels
- [ ] Nascondere tier fuori viewport (no render inutile)

### Bolle vive
- [ ] Tinta bubble = `MoodPalette.auraColor(person.vibe.mood)` se vibe attiva, altrimenti neutro
- [ ] Glow decay: intensità del glow proporzionale a `(72h - timeSinceLastPost) / 72h`
- [ ] Indicatore "Adesso" su bubble se ha postato negli ultimi 30 min (puntino luminoso)
- [ ] Anello pulsante se vibe attiva (TimelineView animation già vista in VibeSetterView)
- [ ] `SelfCenterView` mostra la propria vibe color

### Filtro mutualità
- [ ] `OrbitalFieldView` filtra `people` in input: mostra solo follow mutuali
- [ ] Follow asimmetrici passati a `AsteroidBeltView` (nuovo componente)

### AsteroidBeltView (nuovo)
- [ ] Componente separato, oltre il ring Nebula
- [ ] Bubble piccole (~24px), non strutturate, con drift animato lento
- [ ] Visibile solo a `zoomLevel == .asteroids`
- [ ] Pan orizzontale per esplorare (può essere lunga)
- [ ] Tap → HaloSpace della persona
- [ ] Raggruppamento opzionale per categorie (artisti, brand, etc.)

---

## Fase 3 — Pulse Feed (feed di momenti)

### Struttura
- [ ] `PulseFeedView` — view principale, scroll verticale
- [ ] `FeedViewModel` — `@Observable`, carica `feedPosts()` + vibes
- [ ] `MomentCard` — unità base del feed (vedi spec sotto)
- [ ] `PresenceBar` — strip orizzontale in alto con vibe attive, tier-sorted
- [ ] Sezioni visive per tier (header leggero: "Inner & Close" / "Orbit" / "Nebula")
- [ ] Sezione "Adesso" in testa se ci sono post < 30 min

### MomentCard
- [ ] Portrait con aura mood-color pulsante (usa `SelfCenterView` o nuovo)
- [ ] Nome + tier badge + timestamp
- [ ] Vibe note (se attiva): mood chip + nota testuale
- [ ] Ultimo post dentro la card (foto / testo / audio) — opzionale, se c'è
- [ ] Decay ring visibile intorno al post (anello che si svuota nelle 72h)
- [ ] Reazioni: count per tier Orbit+, chi ha reagito per Inner/Close
- [ ] Card senza post = valida (solo portrait + vibe) — presenza pura

### Dinamismo
- [ ] Realtime Supabase subscribe per nuovi post/vibe nel feed
- [ ] Animazione entrata nuova card in sezione "Adesso"
- [ ] Ping animato per reazione live
- [ ] Sfondo deep space prende leggera tinta dal mood dominante delle card visibili (`withAnimation`)
- [ ] Card che scadono tra < 2h: bordo con colore caldo (warning visivo)

### Integrazione Home
- [ ] `HomeView` ottiene tab/switch tra OrbitalField e PulseFeed
- [ ] Transizione fluida tra i due (no tab bar, gesto swipe o pulsante?)

---

## Fase 4 — Compose vibe-first

### Flow nuovo
- [ ] Rifare `ComposePostView` come `VibeFirstComposeView`
- [ ] Step 1: mood chip selector (obbligatorio, anti-cringe: solo un colore)
- [ ] Step 2: nota testuale 60ch (opzionale, skip esplicito)
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
