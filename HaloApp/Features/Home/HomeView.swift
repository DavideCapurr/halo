import SwiftUI
import HaloShared

/// Schermata principale con shell SWARM: campo full-bleed, rail operativa e
/// command dock custom. Le sheet restano coordinate qui.
struct HomeView: View {
  @State private var me: HaloPersonNode = SeedPeople.me
  @State private var people: [HaloPersonNode] = SeedPeople.all + SeedPeople.asteroids
  @State private var vm = HomeViewModel()
  @State private var peek: HaloPersonNode? = nil
  @State private var showVibeSetter: Bool = false
  @State private var pendingProposal: TierConfirmationSheet.Proposal? = nil
  @State private var fieldZoom: ZoomLevel = .full
  @State private var selectedTab: HaloTabBar.Tab = .orbit
  @State private var showCompose: Bool = false

  /// Conteggio dei tier delle proprie cerchie per il `VibeFirstComposeView`.
  private var tierCounts: [FriendshipTier: Int] {
    Dictionary(grouping: people.filter(\.isMutual), by: \.tier).mapValues(\.count)
  }

  private var asteroids: [HaloPersonNode] { people.filter { !$0.isMutual } }

  private var mutuals: [HaloPersonNode] {
    people.filter(\.isMutual)
  }

  private var activeMutuals: [HaloPersonNode] {
    mutuals.filter(\.hasActiveVibe)
  }

  /// Lista mutuali ordinata per tier-rank, usata come "peers" nelle pagine
  /// HaloSpace così che lo swipe orizzontale resti consistente con l'orbita.
  private var sortedMutuals: [HaloPersonNode] {
    people.filter(\.isMutual)
      .sorted { (a, b) in
        if a.tier.rank != b.tier.rank { return a.tier.rank > b.tier.rank }
        return a.name < b.name
      }
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      DeepSpaceBackground()
      currentTab
        .transition(.opacity.combined(with: .scale(scale: 0.985)))

      HaloTabBar(
        active: selectedTab,
        selfMood: me.mood,
        onSelect: { selectedTab = $0 },
        onCompose: { showCompose = true }
      )
      .padding(.bottom, 8)
    }
    .preferredColorScheme(.dark)
    .animation(SwarmMotion.mount, value: selectedTab)
    .task {
      await vm.load()
      let liveNodes = vm.feedItems.map(HaloPersonNode.init(item:))
      if !liveNodes.isEmpty {
        people = liveNodes
      }
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
          me.mood = newMood
          me.note = newNote
          showVibeSetter = false
        },
        onClose: { showVibeSetter = false }
      )
    }
    .sheet(isPresented: $showCompose) {
      VibeFirstComposeView(
        tierCounts: tierCounts,
        initialMood: me.mood,
        onSend: { result in
          // Demo: aggiorna la propria vibe; il post effettivo passerà da PostsService.post.
          me.mood = result.mood
          me.note = result.note
          showCompose = false
        },
        onClose: { showCompose = false }
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
  }

  @ViewBuilder
  private var currentTab: some View {
    switch selectedTab {
    case .orbit:
      orbitTab
    case .pulse:
      PulseFeedView(onPersonTap: { peek = $0 })
    case .profile:
      ProfileView(
        person: me,
        tierCounts: tierCounts,
        onVibeTap: { showVibeSetter = true },
        onComposeTap: { showCompose = true }
      )
    }
  }

  private var orbitTab: some View {
    ZStack(alignment: .bottom) {
      fieldArea

      VStack(spacing: 0) {
        orbitSystemRail
          .padding(.horizontal, 16)
          .padding(.top, 10)

        Spacer(minLength: 0)

        orbitLiveStrip
          .padding(.bottom, 10)

        orbitConsole
          .padding(.horizontal, 14)
          .padding(.bottom, 8)
      }
    }
  }

  private var orbitSystemRail: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text("HALO / ORBITA")
          .haloEyebrow(SwarmActivationRole.connected.color, size: 8.5, tracking: 2.5)
        Text(Self.dateString)
          .font(HaloType.mono(9, weight: .medium))
          .kerning(1.4)
          .textCase(.uppercase)
          .foregroundStyle(HaloInk.creamMute)
      }

      Rectangle()
        .fill(HaloInk.creamLine)
        .frame(height: 0.5)

      Button(action: { showVibeSetter = true }) {
        HStack(spacing: 7) {
          Circle()
            .fill(MoodPalette.auraColor(me.mood, l: 0.80))
            .frame(width: 7, height: 7)
            .shadow(color: MoodPalette.auraRing(me.mood, alpha: 0.45), radius: 4)
          Text(me.mood.rawValue)
            .font(HaloType.ui(12, weight: .medium))
            .foregroundStyle(HaloInk.cream)
            .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(HaloInk.creamHair, lineWidth: 0.6))
      }
      .buttonStyle(.plain)

      Button(action: { showCompose = true }) {
        Image(systemName: "plus")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(SwarmHalo.background)
          .frame(width: 32, height: 32)
          .background(Circle().fill(SwarmHalo.ink))
      }
      .buttonStyle(.plain)
    }
    .swarmRail()
  }

  private var orbitLiveStrip: some View {
    Group {
      if activeMutuals.isEmpty {
        Text("nessun segnale live")
          .haloEyebrow(HaloInk.creamMute, size: 8, tracking: 1.8)
          .padding(.horizontal, 12)
          .padding(.vertical, 7)
          .swarmChip()
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(activeMutuals.prefix(8)) { person in
              orbitLiveChip(person)
            }
          }
          .padding(.horizontal, 16)
        }
      }
    }
  }

  private func orbitLiveChip(_ person: HaloPersonNode) -> some View {
    Button(action: { peek = person }) {
      HStack(spacing: 8) {
        PortraitView(personId: person.id, size: 24, grayscale: true)
          .background(HaloTheme.portraitBacking, in: Circle())
          .overlay(Circle().strokeBorder(person.tier.swarmHaloState.stroke, lineWidth: 0.6))
        VStack(alignment: .leading, spacing: 1) {
          Text(person.name.lowercased())
            .font(HaloType.ui(11, weight: .semibold))
            .foregroundStyle(HaloInk.cream)
            .lineLimit(1)
          Text(person.mood.rawValue)
            .haloEyebrow(HaloInk.creamMute, size: 6.8, tracking: 1.3)
        }
        Circle()
          .fill(MoodPalette.auraColor(person.mood, l: 0.78))
          .frame(width: 5, height: 5)
      }
      .padding(.horizontal, 9)
      .padding(.vertical, 7)
      .swarmChip(active: true, activation: person.tier == .inner ? .connected : .operational)
    }
    .buttonStyle(.plain)
  }

  private var orbitConsole: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 5) {
        Text("chi è sveglio.")
          .font(HaloType.serif(24, weight: .regular))
          .foregroundStyle(HaloInk.cream)
          .lineLimit(1)
          .minimumScaleFactor(0.76)
        Text("inner · close · orbita")
          .haloEyebrow(HaloInk.creamMute, size: 8.5, tracking: 1.9)
      }

      Spacer(minLength: 8)

      orbitMetric("inner", String(format: "%02d", tierCounts[.inner] ?? 0), accent: fieldZoom == .innerOnly)
      orbitMetric("live", String(format: "%02d", activeMutuals.count), accent: !activeMutuals.isEmpty)
      orbitMetric("range", fieldZoom.shortLabel, accent: fieldZoom != .full)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 13)
    .swarmSurface(.rail, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: .connected)
    .shadow(color: SwarmHalo.absoluteBlack.opacity(0.40), radius: 20, y: 12)
  }

  private func orbitMetric(_ label: String, _ value: String, accent: Bool = false) -> some View {
    SwarmMetricTile(
      label: label,
      value: value,
      activation: accent ? .connected : .rest,
      active: accent
    )
    .frame(width: 42)
  }

  // MARK: - field area (orbital + asteroids)

  private var fieldArea: some View {
    ZStack(alignment: .bottom) {
      OrbitalFieldView(
        people: people,
        me: me,
        pulsing: true,
        onBubbleTap: { peek = $0 },
        onSelfTap: { showVibeSetter = true },
        onSelfLongPress: { showCompose = true },
        onProposeTier: { person, toTier in
          guard let idx = people.firstIndex(where: { $0.id == person.id }) else { return }

          if requiresTierConfirmation(from: person.tier, to: toTier) {
            pendingProposal = .init(person: person, from: person.tier, to: toTier)
          } else {
            people[idx].tier = toTier
          }
        },
        onZoomChange: { fieldZoom = $0 }
      )
      .frame(maxHeight: .infinity)
      .padding(.top, 64)
      .padding(.bottom, fieldZoom == .asteroids ? 166 : 128)

      if fieldZoom == .asteroids && !asteroids.isEmpty {
        AsteroidBeltView(
          people: asteroids,
          onTap: { peek = $0 }
        )
        .padding(.bottom, 92)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
      }
    }
    .animation(SwarmMotion.mount, value: fieldZoom)
  }

  private func requiresTierConfirmation(from: FriendshipTier, to: FriendshipTier) -> Bool {
    from == .nebula && to != .nebula
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
