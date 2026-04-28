import SwiftUI
import HaloShared

/// Schermata principale con `TabView` di sistema: Orbita · Pulse · Tu.
/// Le sheet (peek / vibe / tier / compose) restano coordinate qui.
struct HomeView: View {
  private enum HomeTab: Hashable {
    case orbit
    case pulse
    case profile
  }

  @State private var me: DemoPerson = SeedPeople.me
  @State private var people: [DemoPerson] = SeedPeople.all + SeedPeople.asteroids
  @State private var peek: DemoPerson? = nil
  @State private var showVibeSetter: Bool = false
  @State private var pendingProposal: TierConfirmationSheet.Proposal? = nil
  @State private var fieldZoom: ZoomLevel = .full
  @State private var selectedTab: HomeTab = .orbit
  @State private var showCompose: Bool = false

  /// Conteggio dei tier delle proprie cerchie per il `VibeFirstComposeView`.
  private var tierCounts: [FriendshipTier: Int] {
    Dictionary(grouping: people.filter(\.isMutual), by: \.tier).mapValues(\.count)
  }

  private var asteroids: [DemoPerson] { people.filter { !$0.isMutual } }

  /// Lista mutuali ordinata per tier-rank, usata come "peers" nelle pagine
  /// HaloSpace così che lo swipe orizzontale resti consistente con l'orbita.
  private var sortedMutuals: [DemoPerson] {
    people.filter(\.isMutual)
      .sorted { (a, b) in
        if a.tier.rank != b.tier.rank { return a.tier.rank > b.tier.rank }
        return a.name < b.name
      }
  }

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      TabView(selection: $selectedTab) {
        orbitTab
          .tag(HomeTab.orbit)
          .tabItem {
            Label("Orbita", systemImage: "circle.grid.cross")
          }

        PulseFeedView(onPersonTap: { peek = $0 })
          .tag(HomeTab.pulse)
          .tabItem {
            Label("Pulse", systemImage: "waveform.path.ecg")
          }

        ProfilePlaceholder(me: me, onVibeTap: { showVibeSetter = true })
          .tag(HomeTab.profile)
          .tabItem {
            Label("Tu", systemImage: "person.crop.circle")
          }
      }
      .tint(HaloInk.bronze)
      .toolbarBackground(.ultraThinMaterial, for: .tabBar)
      .toolbarBackground(.visible, for: .tabBar)
    }
    .preferredColorScheme(.dark)
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

  private var orbitTab: some View {
    VStack(spacing: 0) {
      TopBarView(
        mood: me.mood,
        onVibeTap: { showVibeSetter = true },
        onSearchTap: {}
      )
      .padding(.top, 10)

      Text("chi è sveglio.")
        .font(HaloType.serif(14))
        .foregroundStyle(HaloInk.creamLow)
        .padding(.top, 10)

      fieldArea
        .frame(maxHeight: .infinity)
    }
    .padding(.top, 4)
  }

  // MARK: - field area (orbital + asteroids)

  private var fieldArea: some View {
    VStack(spacing: 0) {
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

      if fieldZoom == .asteroids && !asteroids.isEmpty {
        AsteroidBeltView(
          people: asteroids,
          onTap: { peek = $0 }
        )
        .padding(.bottom, 6)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
      }
    }
    .animation(.easeInOut(duration: 0.30), value: fieldZoom)
  }

  private func requiresTierConfirmation(from: FriendshipTier, to: FriendshipTier) -> Bool {
    from == .nebula && to != .nebula
  }
}

extension TierConfirmationSheet.Proposal: Identifiable {
  var id: String { "\(person.id)-\(from.rawValue)-\(to.rawValue)" }
}

// MARK: - Profile placeholder

/// Quick profile destination — keeps the tab usable while the full profile
/// flow (`ProfileView`) is still TODO. Reuses the v2 editorial vocabulary.
private struct ProfilePlaceholder: View {
  let me: DemoPerson
  var onVibeTap: () -> Void = {}

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text(me.name.lowercased())
          .font(HaloType.serif(40, weight: .regular))
          .foregroundStyle(HaloInk.cream)
          .padding(.top, 80)

        HStack(spacing: 8) {
          Circle()
            .fill(MoodPalette.auraColor(me.mood, l: 0.78))
            .frame(width: 7, height: 7)
            .shadow(color: MoodPalette.auraRing(me.mood, alpha: 0.55), radius: 3)
          Text(me.mood.rawValue)
            .haloEyebrow(HaloInk.creamLow, size: 9.5, tracking: 2.4)
          Text("·")
            .haloEyebrow(HaloInk.creamMute)
          Text("@\(me.handle)")
            .haloEyebrow(HaloInk.creamMute)
        }

        Rectangle().fill(HaloInk.creamLine).frame(height: 0.5)

        Button(action: onVibeTap) {
          HStack {
            Text("modifica la tua vibe")
              .font(HaloType.ui(14, weight: .medium))
              .foregroundStyle(HaloInk.cream)
            Spacer()
            Image(systemName: "arrow.up.right")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(HaloInk.creamLow)
          }
          .padding(.vertical, 14)
        }
        .buttonStyle(.plain)

        Rectangle().fill(HaloInk.creamLine).frame(height: 0.5)

        Text("più funzioni in arrivo.")
          .font(HaloType.serif(16))
          .foregroundStyle(HaloInk.creamMute)
          .padding(.top, 12)
      }
      .padding(.horizontal, 26)
      .padding(.bottom, 80)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

#Preview {
  HomeView()
}
