import SwiftUI
import HaloShared

private enum HomeSystemTab: Hashable {
  case orbit
  case pulse
  case compose
  case easy
  case status
  case profile
}

private enum ComposeMediaUploadError: LocalizedError {
  case missingMedia

  var errorDescription: String? {
    "Aggiungi il media prima di mandare il Moment."
  }
}

/// Schermata principale con shell SWARM: campo full-bleed, rail operativa e
/// command dock custom. Le sheet restano coordinate qui.
struct HomeView: View {
  @Environment(AppState.self) private var state
  @State private var me: HaloPersonNode = Self.emptySelfNode
  @State private var people: [HaloPersonNode] = []
  @State private var vm = HomeViewModel()
  @State private var peek: HaloPersonNode? = nil
  @State private var showVibeSetter: Bool = false
  @State private var pendingProposal: TierConfirmationSheet.Proposal? = nil
  @State private var fieldZoom: ZoomLevel = .full
  @State private var selectedTab: HomeSystemTab = .orbit
  @State private var lastContentTab: HomeSystemTab = .orbit
  @State private var showCompose: Bool = false
  @State private var showEasyCompose: Bool = false
  @State private var showStories: Bool = false
  @State private var suppressOrbitHeaderVibeTapUntil: Date? = nil
  @State private var bubbleDrag: BubbleDragState? = nil
  @State private var pinchInProgress: Bool = false
  @State private var zoomDragStartLevel: ZoomLevel? = nil
  @State private var showZoomRail: Bool = false
  @State private var zoomRailHideTask: Task<Void, Never>? = nil
  @State private var pendingInvite: PendingInvite?
  @State private var pendingRing: PendingRing?
  @State private var pendingCampaign: PendingCampaign?
  @State private var showMemoryArchive: Bool = false
  @State private var showPlusFromRoute: Bool = false

  private struct BubbleDragState: Equatable {
    let personId: String
    var ghostTier: FriendshipTier
    var location: CGPoint
  }

  private struct PendingInvite: Identifiable, Equatable {
    let token: String
    var id: String { token }
  }

  private struct PendingRing: Identifiable, Equatable {
    let ringId: UUID?
    let token: String?

    var id: String {
      ringId?.uuidString ?? token ?? "event-ring"
    }
  }

  private struct PendingCampaign: Identifiable, Equatable {
    let campaignId: UUID?
    let slug: String?

    var id: String {
      campaignId?.uuidString ?? slug ?? "campaign"
    }
  }

  private static let orbitCoordinateSpace = "halo.orbitReferenceField"

  /// Conteggio dei tier delle proprie cerchie per il `VibeFirstComposeView`.
  /// Esclude gli asteroid: il compose pensa solo agli amici "vivi" sui ring.
  private var tierCounts: [FriendshipTier: Int] {
    Dictionary(grouping: people.filter { $0.isMutual && $0.tier != .asteroid }, by: \.tier).mapValues(\.count)
  }

  private var asteroids: [HaloPersonNode] { people.filter { !$0.isMutual } }

  /// Mutuali "attivi nell'orbita": esclude chi è stato spinto in `.asteroid`.
  /// Tutto ciò che usa questa lista (storie, hero, contatori, peers swipe)
  /// salta automaticamente i depriorizzati.
  private var mutuals: [HaloPersonNode] {
    people.filter { $0.isMutual && $0.tier != .asteroid }
  }

  private var activeMutuals: [HaloPersonNode] {
    mutuals.filter(\.hasActiveVibe)
  }

  private var orbitStoriesHeroPerson: HaloPersonNode? {
    let liveCandidates = mutuals.filter { $0.hasActiveVibe || $0.hasNew }
    guard !liveCandidates.isEmpty else { return mutuals.first }

    if let innerHero = liveCandidates
      .filter({ $0.tier == .inner })
      .sorted(by: orbitStoriesHeroSort)
      .first {
      return innerHero
    }

    if let orbitHero = liveCandidates
      .filter({ $0.tier == .close || $0.tier == .orbit })
      .sorted(by: orbitStoriesHeroSort)
      .first {
      return orbitHero
    }

    return liveCandidates.sorted(by: orbitStoriesHeroSort).first
  }

  private var orbitStoriesCount: Int {
    let itemStories = vm.mutualItems.filter { item in
      item.viewerTier != .asteroid
        && (item.vibe != nil || (item.lastPost?.isAlive ?? false))
    }.count
    return itemStories > 0 ? itemStories : activeMutuals.count
  }

  private var orbitStoriesCountText: String {
    guard orbitStoriesCount > 0 else { return "0 STORIES · IN ATTESA" }
    return "+\(max(orbitStoriesCount - 1, 0)) STORIES · ADESSO"
  }

  private var orbitalFieldTopInset: CGFloat {
    orbitStoriesHeroPerson == nil ? 64 : 146
  }

  /// Lista mutuali ordinata per tier-rank, usata come "peers" nelle pagine
  /// HaloSpace così che lo swipe orizzontale resti consistente con l'orbita.
  /// Esclude `.asteroid`: chi è negli asteroidi non rientra nello swipe.
  private var sortedMutuals: [HaloPersonNode] {
    people.filter { $0.isMutual && $0.tier != .asteroid }
      .sorted { (a, b) in
        if a.tier.rank != b.tier.rank { return a.tier.rank > b.tier.rank }
        return a.name < b.name
      }
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      orbitTab
        .tag(HomeSystemTab.orbit)
        .tabItem {
          Label("orbita", systemImage: "circle.grid.cross")
        }

      PulseFeedView(onPersonTap: { peek = $0 })
        .tag(HomeSystemTab.pulse)
        .tabItem {
          Label("pulse", systemImage: "waveform.path.ecg")
        }

      Color.clear
        .background(Self.orbitStoriesWarmBlack)
        .tag(HomeSystemTab.compose)
        .tabItem {
          Label("compose", systemImage: "plus.circle")
        }

      Color.clear
        .background(Self.orbitStoriesWarmBlack)
        .tag(HomeSystemTab.easy)
        .tabItem {
          Label("easy", systemImage: "bolt.circle")
        }

      StatoView(
        people: people,
        onTapPerson: { peek = $0 }
      )
      .tag(HomeSystemTab.status)
      .tabItem {
        Label("stato", systemImage: "circle.grid.2x2")
      }

      ProfileView(
        person: me,
        tierCounts: tierCounts,
        onVibeTap: { showVibeSetter = true },
        onComposeTap: { showCompose = true }
      )
      .tag(HomeSystemTab.profile)
      .tabItem {
        Label("tu", systemImage: "person.crop.circle")
      }
    }
    .tint(Self.orbitStoriesCream)
    .preferredColorScheme(.dark)
    .animation(SwarmMotion.mount, value: selectedTab)
    .onChange(of: selectedTab) { _, newValue in
      handleSystemTabSelection(newValue)
    }
    .onChange(of: state.route) { _, _ in
      syncRoutePresentation()
    }
    .task {
      await refreshHomeFromBackend()
      syncRoutePresentation()
    }
    .sheet(item: $peek) { person in
      HaloSpaceView(
        person: person,
        peers: sortedMutuals.isEmpty ? [person] : sortedMutuals,
        onClose: { peek = nil }
      )
    }
    .sheet(isPresented: $showVibeSetter) {
      VibeSetterView(
        initialMood: me.mood,
        initialNote: me.note,
        onSave: { newMood, newNote in
          Task {
            await saveCurrentVibe(mood: newMood, note: newNote)
          }
        },
        onClose: { showVibeSetter = false }
      )
    }
    .sheet(isPresented: $showCompose) {
      VibeFirstComposeView(
        tierCounts: tierCounts,
        initialMood: me.mood,
        onSend: { result in
          Task {
            await sendCompose(result)
          }
        },
        onClose: { showCompose = false }
      )
    }
    .sheet(isPresented: $showEasyCompose) {
      EasyComposeView(
        initialMood: me.mood,
        onSend: { result in
          Task {
            await sendEasyCompose(result)
          }
        },
        onClose: { showEasyCompose = false }
      )
    }
    .sheet(item: $pendingProposal) { proposal in
      TierConfirmationSheet(
        proposal: proposal,
        onAccept: {
          if let idx = people.firstIndex(where: { $0.id == proposal.person.id }) {
            people[idx].tier = proposal.to
          }
          pendingProposal = nil
        },
        onDecline: { pendingProposal = nil }
      )
    }
    .sheet(item: $pendingInvite, onDismiss: {
      if case .invite = state.route {
        state.route = .home
      }
    }) { pending in
      InviteAcceptSheet(token: pending.token)
    }
    .sheet(item: $pendingRing, onDismiss: {
      if case .ring = state.route {
        state.route = .home
      }
      if case .ringJoin = state.route {
        state.route = .home
      }
    }) { pending in
      EventRingView(ringId: pending.ringId, joinToken: pending.token)
    }
    .sheet(item: $pendingCampaign, onDismiss: {
      if case .campaign = state.route {
        state.route = .home
      }
      if case .campaignContribute = state.route {
        state.route = .home
      }
    }) { pending in
      if let id = pending.campaignId {
        CampaignDetailView(campaignId: id)
      } else if let slug = pending.slug {
        CampaignDetailView(contributeSlug: slug)
      }
    }
    .sheet(isPresented: $showMemoryArchive, onDismiss: {
      if case .memory = state.route {
        state.route = .home
      }
    }) {
      MemoryArchiveView(hasPlus: state.currentProfile?.hasPlus ?? false) {
        showMemoryArchive = false
        showPlusFromRoute = true
      }
    }
    .sheet(isPresented: $showPlusFromRoute) {
      PlusUpsellView()
    }
    .fullScreenCover(isPresented: $showStories) {
      OrbitStoriesView(
        items: vm.mutualItems,
        fallbackPeople: activeMutuals,
        onClose: {
          suppressOrbitHeaderVibeTapUntil = .now.addingTimeInterval(0.6)
          showStories = false
        }
      )
      .presentationBackground(.clear)
    }
  }

  private func handleSystemTabSelection(_ tab: HomeSystemTab) {
    switch tab {
    case .compose:
      showCompose = true
      selectedTab = lastContentTab
    case .easy:
      showEasyCompose = true
      selectedTab = lastContentTab
    case .orbit, .pulse, .status, .profile:
      lastContentTab = tab
    }
  }

  private func openOrbitHeaderVibeSetter() {
    if let until = suppressOrbitHeaderVibeTapUntil, Date.now < until {
      return
    }

    showVibeSetter = true
  }

  private func syncRoutePresentation() {
    if case .invite(let token) = state.route {
      pendingInvite = PendingInvite(token: token)
    }
    if case .memory = state.route {
      showMemoryArchive = true
    }
    if case .ring(let id) = state.route {
      pendingRing = PendingRing(ringId: id, token: nil)
    }
    if case .ringJoin(let token) = state.route {
      pendingRing = PendingRing(ringId: nil, token: token)
    }
    if case .campaign(let id) = state.route {
      pendingCampaign = PendingCampaign(campaignId: id, slug: nil)
    }
    if case .campaignContribute(let slug) = state.route {
      pendingCampaign = PendingCampaign(campaignId: nil, slug: slug)
    }
  }

  private var orbitTab: some View {
    ZStack {
      Self.orbitStoriesWarmBlack
        .ignoresSafeArea()

      // Header (card storie) e footer rientrano come inset: il campo occupa
      // lo spazio tra la card in alto e la tab bar in basso, così il centro
      // (self) cade esattamente a metà di quello spazio.
      orbitReferenceFieldArea
        .safeAreaInset(edge: .top, spacing: 0) {
          orbitTopGlassCluster
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
          orbitReferenceInterzoneFooter
        }
    }
  }

  @ViewBuilder
  private var orbitTopGlassCluster: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: 8) {
        orbitTopGlassClusterContent
      }
    } else {
      orbitTopGlassClusterContent
    }
  }

  private var orbitTopGlassClusterContent: some View {
    VStack(spacing: 0) {
      orbitReferenceHeader

      orbitStoriesHeroCard
        .padding(.horizontal, HaloVisual.Orbita.heroHorizontalPadding)
        .padding(.top, HaloVisual.Orbita.heroTopPadding)
    }
  }

  private var orbitReferenceHeader: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 7) {
        Circle()
          .stroke(Self.orbitStoriesCream, lineWidth: 1)
          .frame(width: HaloVisual.Orbita.logoRingSize, height: HaloVisual.Orbita.logoRingSize)
          .padding(.leading, HaloVisual.Orbita.logoRingLeading)

        Text("HALO")
          .font(HaloType.serifUpright(HaloVisual.Orbita.logoTextSize, weight: .regular))
          .kerning(HaloVisual.Orbita.logoTracking)
          .foregroundStyle(Self.orbitStoriesCream)
          .lineLimit(1)
          .padding(.leading, HaloVisual.Orbita.logoTextLeading)
      }
      .padding(.leading, 4)

      Spacer(minLength: 12)

      Button(action: openOrbitHeaderVibeSetter) {
        HStack(spacing: 7) {
          Circle()
            .fill(Self.orbitReferenceMoodColor(orbitReferenceSelfMood))
            .frame(width: HaloVisual.Orbita.vibeDotSize, height: HaloVisual.Orbita.vibeDotSize)
            .shadow(color: Self.orbitReferenceMoodColor(orbitReferenceSelfMood), radius: 8)

          Text(orbitReferenceSelfMood.rawValue)
            .font(Self.orbitStoriesBodyFont(10.5, weight: .medium))
            .kerning(0.42)
            .foregroundStyle(Self.orbitStoriesCream)
            .lineLimit(1)
        }
        .padding(.horizontal, HaloVisual.Orbita.vibePillHorizontalPadding)
        .padding(.vertical, HaloVisual.Orbita.vibePillVerticalPadding)
        .haloGlass(
          in: Capsule(),
          tint: Self.orbitStoriesHeaderPillFill,
          interactive: true,
          stroke: Self.orbitStoriesCreamHair
        )
      }
      .buttonStyle(.plain)
      .padding(.top, HaloVisual.Orbita.vibePillTopPadding)
    }
    .padding(.horizontal, HaloVisual.Orbita.headerHorizontalPadding)
    .padding(.top, HaloVisual.Orbita.headerTopPadding)
    .padding(.bottom, HaloVisual.Orbita.headerBottomPadding)
  }

  @ViewBuilder
  private var orbitStoriesHeroCard: some View {
    if let person = orbitStoriesHeroPerson {
      Button(action: { showStories = true }) {
        HStack(spacing: 12) {
          orbitStoriesHeroPortrait(person)

          VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 0) {
              Text("\(person.name.lowercased()) ")
                .foregroundStyle(Self.orbitStoriesCream)
              Text("vibra")
                .foregroundStyle(Self.orbitStoriesCreamLow)
            }
            .font(HaloType.serif(17, weight: .regular))
            .lineLimit(1)
            .minimumScaleFactor(0.76)

            Text(orbitStoriesCountText)
              .font(HaloType.mono(8.5, weight: .medium))
              .kerning(1.53)
              .foregroundStyle(Self.orbitStoriesCreamMute)
              .lineLimit(1)
          }

          Spacer(minLength: 8)

          Text("→")
            .font(HaloType.serif(18, weight: .regular))
            .foregroundStyle(Self.orbitStoriesBronze)
            .padding(.trailing, 2)
        }
        .padding(.horizontal, HaloVisual.Orbita.heroCardHorizontalPadding)
        .padding(.vertical, HaloVisual.Orbita.heroCardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Self.orbitStoriesCardShape)
        .haloGlass(
          in: Self.orbitStoriesCardShape,
          tint: Self.orbitStoriesCream.opacity(0.04),
          interactive: true,
          stroke: Self.orbitStoriesCreamHair
        )
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Apri stories di \(person.name)")
    }
  }

  private func orbitStoriesHeroPortrait(_ person: HaloPersonNode) -> some View {
    TimelineView(.animation(minimumInterval: 1.0 / 18, paused: !(person.hasActiveVibe || person.hasNew))) { ctx in
      let phase = (sin(ctx.date.timeIntervalSinceReferenceDate * .pi / 2 - .pi / 2) + 1) / 2
      let dotPhase = (sin(ctx.date.timeIntervalSinceReferenceDate * .pi / 1.2 - .pi / 2) + 1) / 2

      ZStack {
        Circle()
          .fill(Self.orbitStoriesWarmBlack)

        Circle()
          .fill(
            RadialGradient(
              colors: [
                Self.orbitReferenceMoodColor(person.mood).opacity(0.36),
                .clear
              ],
              center: UnitPoint(x: 0.32, y: 0.28),
              startRadius: 0,
              endRadius: HaloVisual.Orbita.heroPortraitSize * 0.70
            )
          )

        Text(String(person.name.prefix(1)))
          .font(HaloType.serif(HaloVisual.Orbita.heroPortraitFontSize, weight: .regular))
          .foregroundStyle(Self.orbitStoriesCream)
      }
      .frame(width: HaloVisual.Orbita.heroPortraitSize, height: HaloVisual.Orbita.heroPortraitSize)
      .overlay(alignment: .topTrailing) {
        Circle()
          .fill(Self.orbitStoriesBronze)
          .frame(width: HaloVisual.Orbita.heroDotSize, height: HaloVisual.Orbita.heroDotSize)
          .overlay(Circle().stroke(Self.orbitStoriesWarmBlack, lineWidth: 1.5))
          .shadow(color: Self.orbitStoriesBronze, radius: 5)
          .opacity(0.9 - 0.5 * dotPhase)
      }
      .overlay(Circle().strokeBorder(Self.orbitReferenceMoodColor(person.mood).opacity(0.70), lineWidth: 1))
      .shadow(color: Self.orbitReferenceMoodColor(person.mood), radius: 14)
      .opacity(person.hasActiveVibe || person.hasNew ? 1 - 0.12 * phase : 0.88)
    }
    .frame(width: HaloVisual.Orbita.heroPortraitSize, height: HaloVisual.Orbita.heroPortraitSize)
  }

  private var orbitReferenceFieldArea: some View {
    GeometryReader { proxy in
      let scale = Swift.max(
        HaloVisual.Orbita.fieldMinScale,
        Swift.min(proxy.size.width / HaloVisual.Orbita.fieldBaseWidth, proxy.size.height / HaloVisual.Orbita.fieldBaseHeight)
      )
      let center = CGPoint(x: proxy.size.width * 0.5, y: proxy.size.height * 0.5)
      let radii = orbitReferenceRingRadii(scale: scale)
      let sizes = orbitReferenceBubbleSizes(scale: scale)
      let innerPeople = orbitReferencePeople(for: .inner, limit: 4)
      let closePeople = orbitReferencePeople(for: .close, limit: 9)
      let orbitPeople = orbitReferencePeople(for: .orbit, limit: 8)
      let asteroidPeople = people.filter { $0.isMutual && $0.tier == .asteroid }

      ZStack {
        RadialGradient(
          colors: [
            Self.orbitStoriesBronze.opacity(0.07),
            .clear
          ],
          center: UnitPoint(x: 0.5, y: 0.55),
          startRadius: 0,
          endRadius: Swift.min(proxy.size.width, proxy.size.height) * 0.60
        )

        // Cintura asteroidi: amici depriorizzati, visibili solo in zoom-out.
        if fieldZoom == .asteroids, !asteroidPeople.isEmpty {
          orbitReferenceAsteroidBelt(
            asteroidPeople,
            center: center,
            scale: scale,
            ringRadiusByTier: radii
          )
        }

        if let r = radii[.orbit] {
          orbitReferenceRing(radius: r, center: center, active: bubbleDrag?.ghostTier == .orbit)
        }
        if let r = radii[.close] {
          orbitReferenceRing(radius: r, center: center, active: bubbleDrag?.ghostTier == .close)
        }
        if let r = radii[.inner] {
          orbitReferenceRing(radius: r, center: center, active: bubbleDrag?.ghostTier == .inner)
        }

        if let r = radii[.orbit] {
          ForEach(Array(orbitPeople.enumerated()), id: \.element.id) { index, person in
            orbitReferenceBubble(
              person,
              tier: .orbit,
              size: sizes[.orbit] ?? 0,
              anchor: orbitReferencePosition(
                index: index,
                count: orbitPeople.count,
                radius: r,
                phaseDegrees: -85,
                center: center
              ),
              center: center,
              ringRadiusByTier: radii,
              withLabel: false
            )
          }
        }

        if let r = radii[.close] {
          ForEach(Array(closePeople.enumerated()), id: \.element.id) { index, person in
            orbitReferenceBubble(
              person,
              tier: .close,
              size: sizes[.close] ?? 0,
              anchor: orbitReferencePosition(
                index: index,
                count: closePeople.count,
                radius: r,
                phaseDegrees: -75,
                center: center
              ),
              center: center,
              ringRadiusByTier: radii,
              withLabel: person.hasNew
            )
          }
        }

        if let r = radii[.inner] {
          ForEach(Array(innerPeople.enumerated()), id: \.element.id) { index, person in
            orbitReferenceBubble(
              person,
              tier: .inner,
              size: sizes[.inner] ?? 0,
              anchor: orbitReferencePosition(
                index: index,
                count: innerPeople.count,
                radius: r,
                phaseDegrees: -90,
                center: center
              ),
              center: center,
              ringRadiusByTier: radii,
              withLabel: true
            )
          }
        }

        if let drag = bubbleDrag,
           let from = orbitReferencePersonTier(drag.personId),
           drag.ghostTier != from {
          orbitReferenceGhostHint(target: drag.ghostTier, center: center)
        }

        orbitReferenceSelfCenter(scale: scale * Self.orbitReferenceSelfMultiplier(for: fieldZoom))
          .position(x: center.x, y: center.y)

        orbitReferenceStatusCard(center: center)

        VStack {
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .overlay(alignment: .trailing) {
          orbitReferenceZoomRail
            .padding(.trailing, HaloVisual.Orbita.zoomRailTrailingPadding)
            .opacity(showZoomRail ? 1 : 0.55)
            .animation(.easeInOut(duration: 0.28), value: showZoomRail)
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipped()
      .contentShape(Rectangle())
      .animation(.spring(response: 0.50, dampingFraction: 0.82), value: fieldZoom)
      .gesture(orbitReferencePinchGesture)
      .simultaneousGesture(
        orbitReferenceFieldZoomDragGesture(center: center, ringRadiusByTier: radii)
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .coordinateSpace(name: Self.orbitCoordinateSpace)
    .onDisappear { zoomRailHideTask?.cancel() }
  }

  private func orbitReferenceRing(radius: CGFloat, center: CGPoint, active: Bool = false) -> some View {
    Circle()
      .stroke(
        active ? Self.orbitStoriesBronze.opacity(0.70) : Self.orbitStoriesCreamHair,
        style: StrokeStyle(lineWidth: active ? 1.3 : 1, lineCap: .round, dash: active ? [4, 5] : [2, 6])
      )
      .frame(width: radius * 2, height: radius * 2)
      .position(x: center.x, y: center.y)
      .shadow(color: active ? Self.orbitStoriesBronzeGlow : .clear, radius: 14)
      .allowsHitTesting(false)
  }

  @ViewBuilder
  private func orbitReferenceStatusCard(center: CGPoint) -> some View {
    if vm.isLoading && people.isEmpty {
      SwarmLoadingState(label: "carico orbita")
        .frame(width: 220)
        .position(x: center.x, y: center.y + 112)
        .transition(.opacity)
        .allowsHitTesting(false)
    } else if let lastError = vm.lastError {
      SwarmEmptyState(
        title: "orbita non raggiunta.",
        message: lastError,
        activation: .attention
      )
      .frame(width: 260)
      .position(x: center.x, y: center.y + 130)
      .transition(.opacity)
      .allowsHitTesting(false)
    } else if people.isEmpty {
      SwarmEmptyState(
        title: "orbita vuota.",
        message: "aggiungi il tuo Inner per vedere vibe e Moment qui.",
        activation: .rest
      )
      .frame(width: 260)
      .position(x: center.x, y: center.y + 130)
      .transition(.opacity)
      .allowsHitTesting(false)
    }
  }

  private func orbitReferenceBubble(
    _ person: HaloPersonNode,
    tier: FriendshipTier,
    size: CGFloat,
    anchor: CGPoint,
    center: CGPoint,
    ringRadiusByTier: [FriendshipTier: CGFloat],
    withLabel: Bool
  ) -> some View {
    let isDragging = bubbleDrag?.personId == person.id
    let drawPosition = isDragging ? (bubbleDrag?.location ?? anchor) : anchor

    return orbitReferenceBubbleContent(person, size: size, withLabel: withLabel)
      .contentShape(Circle())
      .scaleEffect(isDragging ? 1.08 : 1)
      .shadow(color: isDragging ? Self.orbitStoriesBronzeGlow : .clear, radius: isDragging ? 14 : 0)
      .position(x: drawPosition.x, y: drawPosition.y)
      .zIndex(isDragging ? 50 : 10)
      .animation(isDragging ? nil : .spring(response: 0.55, dampingFraction: 0.78), value: drawPosition)
      .accessibilityLabel(person.name)
      .accessibilityAddTraits(.isButton)
      .onTapGesture {
        HapticEngine.tap(for: tier)
        peek = person
      }
      .gesture(
        orbitReferenceBubbleDragGesture(
          person: person,
          originalTier: tier,
          center: center,
          ringRadiusByTier: ringRadiusByTier
        )
      )
  }

  /// Cintura asteroidi: mutuali depriorizzati renderizzati oltre l'anello orbit.
  /// Bubble piccoli e attenuati, ma con la stessa gesture di drag dei ring così
  /// l'utente può ri-promuoverli trascinandoli verso il centro.
  @ViewBuilder
  private func orbitReferenceAsteroidBelt(
    _ asteroidPeople: [HaloPersonNode],
    center: CGPoint,
    scale: CGFloat,
    ringRadiusByTier: [FriendshipTier: CGFloat]
  ) -> some View {
    let beltRadius = (ringRadiusByTier[.orbit] ?? 142 * scale) + 56 * scale
    let beltSize = Swift.max(12, 16 * scale)

    ForEach(Array(asteroidPeople.enumerated()), id: \.element.id) { index, person in
      orbitReferenceBubble(
        person,
        tier: .asteroid,
        size: beltSize,
        anchor: orbitReferencePosition(
          index: index,
          count: asteroidPeople.count,
          radius: beltRadius,
          phaseDegrees: -100,
          center: center
        ),
        center: center,
        ringRadiusByTier: ringRadiusByTier,
        withLabel: false
      )
      .opacity(0.62)
    }
  }

  private func orbitReferenceGhostHint(target: FriendshipTier, center: CGPoint) -> some View {
    HStack(spacing: 6) {
      Text("sposta in")
        .foregroundStyle(Self.orbitStoriesCreamMute)
      Text(target.label.lowercased())
        .fontWeight(.semibold)
        .foregroundStyle(Self.orbitStoriesCream)
    }
    .font(HaloType.mono(10, weight: .medium))
    .kerning(1.4)
    .textCase(.uppercase)
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
    .haloGlass(
      in: Capsule(),
      tint: Self.orbitStoriesHeaderPillFill,
      stroke: Self.orbitStoriesBronze.opacity(0.55)
    )
    .shadow(color: Self.orbitStoriesBronzeGlow, radius: 14)
    .position(x: center.x, y: 30)
    .zIndex(60)
    .transition(.opacity.combined(with: .move(edge: .top)))
    .allowsHitTesting(false)
  }

  private func orbitReferenceBubbleContent(
    _ person: HaloPersonNode,
    size: CGFloat,
    withLabel: Bool
  ) -> some View {
    let active = person.hasActiveVibe
    let frameSize = Swift.max(82, size + 58)

    return TimelineView(.animation(minimumInterval: 1.0 / 18, paused: !active)) { ctx in
      let breath = (sin(ctx.date.timeIntervalSinceReferenceDate * .pi / 2 - .pi / 2) + 1) / 2
      let blink = (sin(ctx.date.timeIntervalSinceReferenceDate * .pi / 1.2 - .pi / 2) + 1) / 2

      ZStack {
        orbitReferenceBubbleCircle(person, size: size, breath: breath, blink: blink)

        if withLabel {
          orbitReferenceBubbleLabel(person.name, size: size)
        }
      }
      .frame(width: frameSize, height: frameSize)
    }
  }

  private func orbitReferenceBubbleCircle(
    _ person: HaloPersonNode,
    size: CGFloat,
    breath: Double,
    blink: Double
  ) -> some View {
    let active = person.hasActiveVibe
    let dotSize = Swift.max(5, size * 0.16)
    let stroke = active
      ? Self.orbitReferenceMoodColor(person.mood).opacity(0.65)
      : Self.orbitStoriesCreamHair

    return ZStack {
      Circle()
        .fill(Self.orbitStoriesCreamWhisper)

      if active {
        Circle()
          .fill(
            RadialGradient(
              colors: [
                Self.orbitReferenceMoodColor(person.mood).opacity(0.22),
                .clear
              ],
              center: UnitPoint(x: 0.35, y: 0.30),
              startRadius: 0,
              endRadius: size * 0.70
            )
          )
      }

      Text(String(person.name.prefix(1)))
        .font(HaloType.serif((size * 0.42).rounded(), weight: .regular))
        .foregroundStyle(Self.orbitStoriesCream)
    }
    .frame(width: size, height: size)
    .overlay(Circle().strokeBorder(stroke, lineWidth: 1))
    .overlay(alignment: .topTrailing) {
      if person.hasNew {
        Circle()
          .fill(Self.orbitStoriesBronze)
          .frame(width: dotSize, height: dotSize)
          .shadow(color: Self.orbitStoriesBronzeGlow, radius: 6)
          .opacity(0.9 - 0.5 * blink)
      }
    }
    .shadow(
      color: active ? Self.orbitReferenceMoodColor(person.mood).opacity(0.88) : .clear,
      radius: size * 0.30
    )
    .shadow(
      color: active ? Self.orbitReferenceMoodColor(person.mood, alpha: 0.35) : .clear,
      radius: size * 0.55
    )
    .opacity(active ? 1 - 0.12 * breath : 0.45)
  }

  private func orbitReferenceBubbleLabel(_ name: String, size: CGFloat) -> some View {
    Text(name)
      .font(HaloType.serif(size > 34 ? 12 : 10, weight: .regular))
      .foregroundStyle(Self.orbitStoriesCream)
      .lineLimit(1)
      .fixedSize()
      .shadow(color: Self.orbitStoriesWarmBlack, radius: 8)
      .offset(y: size * 0.5 + 10)
  }

  private func orbitReferenceSelfCenter(scale: CGFloat) -> some View {
    let outer = HaloVisual.Orbita.selfOuterSize * scale
    let inner = HaloVisual.Orbita.selfInnerSize * scale
    let name = orbitReferenceSelfDisplayName

    return ZStack {
      Circle()
        .stroke(Self.orbitReferenceMoodColor(orbitReferenceSelfMood).opacity(0.55), lineWidth: 1)
        .frame(width: outer, height: outer)

      ZStack {
        Circle()
          .fill(Self.orbitStoriesNightSurface)

        Circle()
          .fill(
            RadialGradient(
              colors: [
                Self.orbitReferenceMoodColor(orbitReferenceSelfMood).opacity(0.42),
                .clear
              ],
              center: UnitPoint(x: 0.32, y: 0.28),
              startRadius: 0,
              endRadius: inner * 0.70
            )
          )

        Text(String(name.prefix(1)))
          .font(HaloType.serif(19 * scale, weight: .regular))
          .foregroundStyle(Self.orbitStoriesCream)
      }
      .frame(width: inner, height: inner)
      .overlay(Circle().strokeBorder(Self.orbitReferenceMoodColor(orbitReferenceSelfMood).opacity(0.70), lineWidth: 1))
      .shadow(color: Self.orbitReferenceMoodColor(orbitReferenceSelfMood), radius: 18 * scale)
      .shadow(color: Self.orbitReferenceMoodColor(orbitReferenceSelfMood, alpha: 0.35), radius: 32 * scale)

      Text(name)
        .font(HaloType.serif(14 * scale, weight: .regular))
        .foregroundStyle(Self.orbitStoriesCream)
        .lineLimit(1)
        .fixedSize()
        .shadow(color: Self.orbitStoriesWarmBlack, radius: 10)
        .offset(y: outer * 0.5 + 14 * scale)
    }
    .frame(width: HaloVisual.Orbita.selfFrameSize * scale, height: HaloVisual.Orbita.selfFrameSize * scale)
    .contentShape(Rectangle())
    .onTapGesture { showVibeSetter = true }
    .onLongPressGesture { showCompose = true }
  }

  private var orbitReferenceZoomRail: some View {
    let railHeight = HaloVisual.Orbita.zoomRailLineHeight
    let levels = ZoomLevel.allCases
    let activeIndex = fieldZoom.rawValue

    return VStack(spacing: 8) {
      Button {
        applyZoom(fieldZoom.zoomedIn(), reveal: true)
      } label: {
        Text("+")
          .font(Self.orbitStoriesBodyFont(12, weight: .regular))
          .foregroundStyle(fieldZoom == .innerOnly ? Self.orbitStoriesCreamMute : Self.orbitStoriesCreamLow)
          .frame(width: 18, height: 12)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(fieldZoom == .innerOnly)

      ZStack(alignment: .top) {
        Rectangle()
          .fill(Self.orbitStoriesCreamLine)
          .frame(width: 2, height: railHeight)

        ForEach(levels.indices, id: \.self) { index in
          let level = levels[index]
          let active = index == activeIndex
          let dotSize: CGFloat = active ? 8 : 5
          Circle()
            .fill(active ? Self.orbitStoriesBronze : Self.orbitStoriesCreamHair)
            .frame(width: dotSize, height: dotSize)
            .shadow(color: active ? Self.orbitStoriesBronzeGlow : .clear, radius: 6)
            .offset(y: CGFloat(index) / CGFloat(levels.count - 1) * railHeight - dotSize / 2)
            .contentShape(Rectangle().inset(by: -10))
            .onTapGesture { applyZoom(level, reveal: true) }
        }
      }
      .frame(width: 22, height: railHeight)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            let y = Swift.min(Swift.max(value.location.y, 0), railHeight)
            let raw = Int((y / railHeight * CGFloat(levels.count - 1)).rounded())
            let clamped = Swift.min(Swift.max(raw, 0), levels.count - 1)
            applyZoom(levels[clamped], reveal: true)
          }
      )

      Button {
        applyZoom(fieldZoom.zoomedOut(), reveal: true)
      } label: {
        Text("−")
          .font(Self.orbitStoriesBodyFont(14, weight: .regular))
          .foregroundStyle(fieldZoom == .asteroids ? Self.orbitStoriesCreamMute : Self.orbitStoriesCreamLow)
          .frame(width: 18, height: 14)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(fieldZoom == .asteroids)
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 10)
    .background(Self.orbitStoriesZoomRailFill, in: Capsule())
    .haloGlass(
      in: Capsule(),
      tint: Self.orbitStoriesZoomRailFill,
      interactive: true,
      stroke: Self.orbitStoriesCreamHair
    )
    .overlay(Capsule().strokeBorder(Self.orbitStoriesCreamHair, lineWidth: 1))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Zoom orbita")
    .accessibilityValue(fieldZoom.shortLabel)
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: applyZoom(fieldZoom.zoomedOut(), reveal: true)
      case .decrement: applyZoom(fieldZoom.zoomedIn(), reveal: true)
      @unknown default: break
      }
    }
  }

  private var orbitReferenceInterzoneFooter: some View {
    Text("tieni premuto al centro per condividere")
      .font(HaloType.eyebrow(8))
      .kerning(1.92)
      .foregroundStyle(Self.orbitStoriesCreamMute)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity)
      .allowsHitTesting(false)
  }

  private func orbitReferencePeople(for tier: FriendshipTier, limit: Int) -> [HaloPersonNode] {
    return Array(
      mutuals
        .filter { $0.tier == tier }
        .sorted(by: orbitReferenceBubbleSort)
        .prefix(limit)
    )
  }

  private func orbitReferenceBubbleSort(_ lhs: HaloPersonNode, _ rhs: HaloPersonNode) -> Bool {
    if lhs.hasNew != rhs.hasNew { return lhs.hasNew && !rhs.hasNew }
    if lhs.hasActiveVibe != rhs.hasActiveVibe { return lhs.hasActiveVibe && !rhs.hasActiveVibe }

    let lhsActivity = lhs.lastActivityAt ?? .distantPast
    let rhsActivity = rhs.lastActivityAt ?? .distantPast
    if lhsActivity != rhsActivity { return lhsActivity > rhsActivity }

    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
  }

  private func orbitReferencePosition(
    index: Int,
    count: Int,
    radius: CGFloat,
    phaseDegrees: Double,
    center: CGPoint
  ) -> CGPoint {
    guard count > 0 else { return center }

    let angle = (Double(index) * 360 / Double(count) + phaseDegrees) * .pi / 180
    return CGPoint(
      x: center.x + CGFloat(cos(angle)) * radius,
      y: center.y + CGFloat(sin(angle)) * radius
    )
  }

  // MARK: - Zoom-aware sizing

  private func orbitReferenceRingRadii(scale: CGFloat) -> [FriendshipTier: CGFloat] {
    var radii: [FriendshipTier: CGFloat] = [:]
    for tier in FriendshipTier.allCases where Self.orbitReferenceTierVisible(tier, zoom: fieldZoom) {
      radii[tier] = Self.orbitReferenceRingRadius(tier, zoom: fieldZoom) * scale
    }
    return radii
  }

  private func orbitReferenceBubbleSizes(scale: CGFloat) -> [FriendshipTier: CGFloat] {
    var sizes: [FriendshipTier: CGFloat] = [:]
    for tier in FriendshipTier.allCases where Self.orbitReferenceTierVisible(tier, zoom: fieldZoom) {
      sizes[tier] = Self.orbitReferenceBubbleSize(tier, zoom: fieldZoom) * scale
    }
    return sizes
  }

  private static func orbitReferenceRingRadius(_ tier: FriendshipTier, zoom: ZoomLevel) -> CGFloat {
    switch (tier, zoom) {
    case (.inner,  .innerOnly):  return 122
    case (.close,  .innerOnly):  return 0
    case (.orbit,  .innerOnly):  return 0
    case (.nebula, .innerOnly):  return 0

    case (.inner,  .innerClose): return 68
    case (.close,  .innerClose): return 152
    case (.orbit,  .innerClose): return 0
    case (.nebula, .innerClose): return 0

    case (.inner,  .full):       return HaloVisual.Orbita.innerRadius
    case (.close,  .full):       return HaloVisual.Orbita.closeRadius
    case (.orbit,  .full):       return HaloVisual.Orbita.orbitRadius
    case (.nebula, .full):       return 0

    case (.inner,  .asteroids):  return 56
    case (.close,  .asteroids):  return 100
    case (.orbit,  .asteroids):  return 142
    case (.nebula, .asteroids):  return 0

    case (.asteroid, _):         return 0
    }
  }

  private static func orbitReferenceBubbleSize(_ tier: FriendshipTier, zoom: ZoomLevel) -> CGFloat {
    switch (tier, zoom) {
    case (.inner,  .innerOnly):  return 62
    case (.close,  .innerOnly):  return 0
    case (.orbit,  .innerOnly):  return 0
    case (.nebula, .innerOnly):  return 0

    case (.inner,  .innerClose): return 44
    case (.close,  .innerClose): return 32
    case (.orbit,  .innerClose): return 0
    case (.nebula, .innerClose): return 0

    case (.inner,  .full):       return HaloVisual.Orbita.innerBubbleSize
    case (.close,  .full):       return HaloVisual.Orbita.closeBubbleSize
    case (.orbit,  .full):       return HaloVisual.Orbita.orbitBubbleSize
    case (.nebula, .full):       return 0

    case (.inner,  .asteroids):  return 28
    case (.close,  .asteroids):  return 22
    case (.orbit,  .asteroids):  return 16
    case (.nebula, .asteroids):  return 0

    case (.asteroid, _):         return 0
    }
  }

  private static func orbitReferenceTierVisible(_ tier: FriendshipTier, zoom: ZoomLevel) -> Bool {
    switch (tier, zoom) {
    case (.inner, _):                                    return true
    case (.close, .innerOnly):                           return false
    case (.close, _):                                    return true
    case (.orbit, .innerOnly), (.orbit, .innerClose):    return false
    case (.orbit, _):                                    return true
    case (.nebula, _):                                   return false
    case (.asteroid, _):                                 return false
    }
  }

  private static func orbitReferenceSelfMultiplier(for zoom: ZoomLevel) -> CGFloat {
    switch zoom {
    case .innerOnly:  return 1.42
    case .innerClose: return 1.18
    case .full:       return 1.0
    case .asteroids:  return 0.82
    }
  }

  private func orbitReferencePersonTier(_ personId: String) -> FriendshipTier? {
    mutuals.first(where: { $0.id == personId })?.tier
  }

  // MARK: - Field gestures

  private var orbitReferencePinchGesture: some Gesture {
    MagnificationGesture(minimumScaleDelta: 0.05)
      .onChanged { scale in
        guard !pinchInProgress else { return }
        if scale > 1.22 {
          pinchInProgress = true
          applyZoom(fieldZoom.zoomedIn(), reveal: true)
        } else if scale < 0.82 {
          pinchInProgress = true
          applyZoom(fieldZoom.zoomedOut(), reveal: true)
        }
      }
      .onEnded { _ in pinchInProgress = false }
  }

  private func orbitReferenceFieldZoomDragGesture(
    center: CGPoint,
    ringRadiusByTier: [FriendshipTier: CGFloat]
  ) -> some Gesture {
    DragGesture(minimumDistance: 22, coordinateSpace: .named(Self.orbitCoordinateSpace))
      .onChanged { value in
        guard bubbleDrag == nil else { return }
        guard !orbitReferenceLocationOverBubble(
          value.startLocation,
          center: center,
          ringRadiusByTier: ringRadiusByTier
        ) else { return }

        let dx = value.translation.width
        let dy = value.translation.height
        guard abs(dy) > abs(dx) * 1.2 else { return }

        let start = zoomDragStartLevel ?? fieldZoom
        zoomDragStartLevel = start
        let steps = Int((dy / 64).rounded())
        let raw = Swift.min(
          Swift.max(start.rawValue + steps, ZoomLevel.innerOnly.rawValue),
          ZoomLevel.asteroids.rawValue
        )
        guard let next = ZoomLevel(rawValue: raw), next != fieldZoom else { return }
        applyZoom(next, reveal: true)
      }
      .onEnded { _ in zoomDragStartLevel = nil }
  }

  private func orbitReferenceBubbleDragGesture(
    person: HaloPersonNode,
    originalTier: FriendshipTier,
    center: CGPoint,
    ringRadiusByTier: [FriendshipTier: CGFloat]
  ) -> some Gesture {
    DragGesture(minimumDistance: 8, coordinateSpace: .named(Self.orbitCoordinateSpace))
      .onChanged { value in
        let target = orbitReferenceNearestTargetTier(
          to: value.location,
          ringRadiusByTier: ringRadiusByTier,
          center: center
        )
        if bubbleDrag?.ghostTier != target {
          HapticEngine.selection()
        }
        bubbleDrag = BubbleDragState(personId: person.id, ghostTier: target, location: value.location)
      }
      .onEnded { _ in
        guard let drag = bubbleDrag, drag.personId == person.id else { return }
        defer { bubbleDrag = nil }
        guard drag.ghostTier != originalTier else { return }
        HapticEngine.tap(for: drag.ghostTier)
        pendingProposal = TierConfirmationSheet.Proposal(
          person: person,
          from: originalTier,
          to: drag.ghostTier
        )
      }
  }

  private func orbitReferenceNearestTargetTier(
    to location: CGPoint,
    ringRadiusByTier: [FriendshipTier: CGFloat],
    center: CGPoint
  ) -> FriendshipTier {
    let distance = hypot(location.x - center.x, location.y - center.y)
    // Oltre l'anello più esterno (+ margine): gesto "lancia fuori" → asteroidi.
    // Soglia < raggio della cintura (orbit + 56·scale) così i bubble già nella
    // fascia restano in zona asteroide finché non li trascini decisamente dentro.
    let outerRadius = ringRadiusByTier.values.max() ?? 0
    if outerRadius > 0, distance > outerRadius + 40 { return .asteroid }
    var best: FriendshipTier = .orbit
    var bestDiff: CGFloat = .infinity
    for (tier, radius) in ringRadiusByTier where tier != .nebula {
      let diff = abs(distance - radius)
      if diff < bestDiff {
        bestDiff = diff
        best = tier
      }
    }
    return best
  }

  private func orbitReferenceLocationOverBubble(
    _ location: CGPoint,
    center: CGPoint,
    ringRadiusByTier: [FriendshipTier: CGFloat]
  ) -> Bool {
    let selfReach = HaloVisual.Orbita.selfFrameSize * Self.orbitReferenceSelfMultiplier(for: fieldZoom) * 0.42
    let distance = hypot(location.x - center.x, location.y - center.y)
    if distance <= selfReach { return true }
    for (_, radius) in ringRadiusByTier {
      if abs(distance - radius) <= 28 { return true }
    }
    return false
  }

  private func applyZoom(_ level: ZoomLevel, reveal: Bool) {
    revealZoomRail(reveal)
    guard level != fieldZoom else { return }
    HapticEngine.selection()
    withAnimation(.spring(response: 0.50, dampingFraction: 0.82)) {
      fieldZoom = level
    }
  }

  private func revealZoomRail(_ flag: Bool) {
    guard flag else { return }
    zoomRailHideTask?.cancel()
    if !showZoomRail {
      withAnimation(.easeInOut(duration: 0.18)) { showZoomRail = true }
    }
    zoomRailHideTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: 1_800_000_000)
      if !Task.isCancelled {
        withAnimation(.easeInOut(duration: 0.28)) { showZoomRail = false }
      }
    }
  }

  @MainActor
  private func refreshHomeFromBackend() async {
    hydrateCurrentProfile()
    await vm.load()
    people = vm.feedItems.map(HaloPersonNode.init(item:))
  }

  @MainActor
  private func hydrateCurrentProfile() {
    guard let profile = state.currentProfile else { return }
    me = Self.selfNode(from: profile, fallback: me)
  }

  @MainActor
  private func saveCurrentVibe(mood: Mood, note: String) async {
    do {
      let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
      _ = try await VibesService.shared.setCurrent(
        mood: mood,
        colorHex: mood.defaultHex,
        note: trimmed.isEmpty ? nil : trimmed
      )
      me.mood = mood
      me.note = trimmed
      me.hasActiveVibe = true
      me.lastVibeAt = .now
      showVibeSetter = false
      await refreshHomeFromBackend()
    } catch {
      vm.lastError = SupabaseErrorMessage.describe(
        error,
        fallback: "Non riesco a mandare la vibe. Riprova."
      )
    }
  }

  @MainActor
  private func sendCompose(_ result: VibeFirstComposeView.ComposeResult) async {
    do {
      let trimmed = result.note.trimmingCharacters(in: .whitespacesAndNewlines)
      let postKind = Self.postKind(for: result.momento)
      let mediaPath = try await uploadComposeMedia(result.media, for: postKind)
      var insertedPost: HaloPost?

      _ = try await VibesService.shared.setCurrent(
        mood: result.mood,
        colorHex: result.mood.defaultHex,
        note: trimmed.isEmpty ? nil : trimmed
      )

      if let postKind {
        insertedPost = try await PostsService.shared.post(
          kind: postKind,
          mediaPath: mediaPath,
          caption: trimmed.isEmpty ? nil : trimmed,
          mood: result.mood,
          minTier: result.tier,
          lifespan: .standard
        )
      }

      me.mood = result.mood
      me.note = trimmed
      me.hasActiveVibe = true
      me.lastVibeAt = .now
      if let insertedPost {
        me.lastPostAt = insertedPost.createdAt
        me.lastPostId = insertedPost.id
        me.lastPostKind = insertedPost.kind
        me.lastPostCaption = insertedPost.caption
        me.lastPostMediaPath = insertedPost.mediaPath
        me.lastPostExpiresAt = insertedPost.expiresAt
      }
      showCompose = false
      await refreshHomeFromBackend()
    } catch {
      vm.lastError = SupabaseErrorMessage.describe(
        error,
        fallback: "Non riesco a mandare il Moment. Riprova."
      )
    }
  }

  private func uploadComposeMedia(
    _ media: VibeFirstComposeView.MediaPayload?,
    for postKind: PostKind?
  ) async throws -> String? {
    guard let postKind else { return nil }

    switch (postKind, media) {
    case (.photo, .data(let data, let contentType)),
         (.audio, .data(let data, let contentType)):
      return try await StorageService.shared.uploadPostMedia(data: data, contentType: contentType)

    case (.photo, .file(let url, let contentType)),
         (.audio, .file(let url, let contentType)):
      let data = try Data(contentsOf: url)
      return try await StorageService.shared.uploadPostMedia(data: data, contentType: contentType)

    case (.text, _):
      return nil

    case (.photo, nil), (.audio, nil):
      throw ComposeMediaUploadError.missingMedia
    }
  }

  @MainActor
  private func sendEasyCompose(_ result: EasyComposeView.Result) async {
    do {
      let trimmed = result.note.trimmingCharacters(in: .whitespacesAndNewlines)
      _ = try await VibesService.shared.setCurrent(
        mood: result.mood,
        colorHex: result.mood.defaultHex,
        note: trimmed.isEmpty ? nil : trimmed
      )
      _ = try await PostsService.shared.post(
        kind: .text,
        mediaPath: nil,
        caption: trimmed.isEmpty ? nil : trimmed,
        mood: result.mood,
        minTier: .inner,
        lifespan: .easy
      )

      me.mood = result.mood
      me.note = trimmed
      me.hasActiveVibe = true
      me.lastVibeAt = .now
      me.lastPostAt = .now
      me.lastPostKind = .text
      showEasyCompose = false
      await refreshHomeFromBackend()
    } catch {
      vm.lastError = SupabaseErrorMessage.describe(
        error,
        fallback: "Non riesco a mandare l'easy Moment. Riprova."
      )
    }
  }

  private var orbitReferenceSelfDisplayName: String {
    let displayName = me.name.trimmingCharacters(in: .whitespacesAndNewlines)
    return displayName.isEmpty ? "tu" : displayName.lowercased()
  }

  private var orbitReferenceSelfMood: Mood {
    me.mood
  }

  private static func orbitReferenceMoodColor(_ mood: Mood, alpha: Double = 1) -> Color {
    HaloVisual.Aura.color(mood, alpha: alpha)
  }

  private static func selfNode(from profile: Profile, fallback: HaloPersonNode) -> HaloPersonNode {
    HaloPersonNode(
      id: profile.id.uuidString,
      handle: profile.handle,
      name: profile.displayName,
      tier: .inner,
      mood: fallback.mood,
      note: fallback.note,
      hasNew: fallback.hasNew,
      lastPostAt: fallback.lastPostAt,
      lastPostKind: fallback.lastPostKind,
      lastVibeAt: fallback.lastVibeAt,
      hasActiveVibe: fallback.hasActiveVibe,
      isMutual: true
    )
  }

  private static func postKind(for momento: VibeFirstComposeView.Momento) -> PostKind? {
    switch momento {
    case .foto: return .photo
    case .testo: return .text
    case .audio: return .audio
    case .salta: return nil
    }
  }

  private static func orbitStoriesBodyFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    HaloVisual.Typography.inter(size, weight: weight)
  }

  private static let orbitStoriesCream = HaloVisual.Palette.cream
  private static let orbitStoriesWarmBlack = HaloVisual.Palette.warmBlack
  private static let orbitStoriesNightSurface = HaloVisual.Palette.nightSurface
  private static let orbitStoriesBronze = HaloVisual.Palette.bronze
  private static let orbitStoriesCreamLow = HaloVisual.Palette.creamLow
  private static let orbitStoriesCreamMute = HaloVisual.Palette.creamMute
  private static let orbitStoriesCreamHair = HaloVisual.Palette.creamHair
  private static let orbitStoriesCreamLine = HaloVisual.Palette.creamLine
  private static let orbitStoriesCreamWhisper = HaloVisual.Palette.creamWhisper
  private static let orbitStoriesBronzeGlow = HaloVisual.Palette.bronzeGlow
  private static let orbitStoriesHeaderPillFill = HaloVisual.Palette.glassInkFill.opacity(HaloVisual.Orbita.headerPillFillOpacity)
  private static let orbitStoriesZoomRailFill = HaloVisual.Palette.glassInkFill.opacity(HaloVisual.Orbita.zoomRailFillOpacity)

  private static let emptySelfNode = HaloPersonNode(
    id: "self",
    handle: "you",
    name: "tu",
    tier: .inner,
    mood: .chill,
    note: "",
    hasNew: false,
    lastPostAt: nil,
    lastVibeAt: nil,
    hasActiveVibe: false,
    isMutual: true
  )

  private static var orbitStoriesCardShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: HaloVisual.Orbita.heroCardRadius, style: .continuous)
  }

  private func orbitStoriesHeroSort(_ lhs: HaloPersonNode, _ rhs: HaloPersonNode) -> Bool {
    if lhs.tier.rank != rhs.tier.rank { return lhs.tier.rank > rhs.tier.rank }
    if lhs.hasNew != rhs.hasNew { return lhs.hasNew && !rhs.hasNew }

    let lhsActivity = orbitStoriesActivityDate(for: lhs)
    let rhsActivity = orbitStoriesActivityDate(for: rhs)
    if lhsActivity != rhsActivity { return lhsActivity > rhsActivity }

    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
  }

  private func orbitStoriesActivityDate(for person: HaloPersonNode) -> Date {
    if let uuid = UUID(uuidString: person.id),
       let item = vm.mutualItems.first(where: { $0.id == uuid }) {
      return item.lastActivityAt
    }

    return person.lastPostAt ?? .distantPast
  }

  private static var dateString: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "it_IT")
    formatter.setLocalizedDateFormatFromTemplate("EEE d")
    return formatter.string(from: .now).replacingOccurrences(of: ".", with: "")
  }
}

private extension ZoomLevel {
  var shortLabel: String {
    switch self {
    case .innerOnly: return "INN"
    case .innerClose: return "CLO"
    case .full: return "ORB"
    case .asteroids: return "OUT"
    }
  }
}

extension TierConfirmationSheet.Proposal: Identifiable {
  var id: String { "\(person.id)-\(from.rawValue)-\(to.rawValue)" }
}

#Preview {
  HomeView()
}
