import SwiftUI
import HaloShared

/// Schermata principale: background Deep Space + TopBar + (OrbitalField | PulseFeed) + BottomBar
/// + sheets (peek / vibe setter / tier confirm).
/// Switch tra le due viste tramite swipe orizzontale o pulsanti dedicati nella BottomBar.
struct HomeView: View {
  enum Tab: Hashable {
    case orbit
    case pulse
  }

  @State private var me: DemoPerson = SeedPeople.me
  @State private var people: [DemoPerson] = SeedPeople.all + SeedPeople.asteroids
  @State private var peek: DemoPerson? = nil
  @State private var showVibeSetter: Bool = false
  @State private var pendingProposal: TierConfirmationSheet.Proposal? = nil
  @State private var fieldZoom: ZoomLevel = .full
  @State private var selectedTab: Tab = .orbit
  @State private var showCompose: Bool = false

  /// Conteggio dei tier delle proprie cerchie per il `VibeFirstComposeView`.
  private var tierCounts: [FriendshipTier: Int] {
    Dictionary(grouping: people.filter(\.isMutual), by: \.tier).mapValues(\.count)
  }

  private var asteroids: [DemoPerson] { people.filter { !$0.isMutual } }

  var body: some View {
    ZStack {
      DeepSpaceBackground()

      TabView(selection: $selectedTab) {
        orbitTab
          .tag(Tab.orbit)
          .tabItem {
            Label("Orbita", systemImage: "circle.dotted")
          }

        PulseFeedView(onPersonTap: { peek = $0 })
          .tag(Tab.pulse)
          .tabItem {
            Label("Pulse", systemImage: "list.dash")
          }
      }
      .tint(.white)
      .animation(.easeInOut(duration: 0.30), value: fieldZoom)

      composeButton
    }
    .preferredColorScheme(.dark)
    .sheet(item: $peek) { person in
      HaloSpacePeekSheet(person: person)
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

  // MARK: - tabs

  private var orbitTab: some View {
    VStack(spacing: 0) {
      TopBarView(
        mood: me.mood,
        onVibeTap: { showVibeSetter = true },
        onSearchTap: {}
      )
      .padding(.top, 8)

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
  }

  private var composeButton: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button {
          showCompose = true
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 54, height: 54)
            .haloGlass(in: Circle(), tint: MoodPalette.auraColor(me.mood, l: 0.58), interactive: true)
            .shadow(color: MoodPalette.auraRing(me.mood, alpha: 0.24), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 18)
        .padding(.bottom, 74)
      }
    }
    .allowsHitTesting(true)
  }

  private func requiresTierConfirmation(from: FriendshipTier, to: FriendshipTier) -> Bool {
    from == .nebula && to != .nebula
  }
}

extension TierConfirmationSheet.Proposal: Identifiable {
  var id: String { "\(person.id)-\(from.rawValue)-\(to.rawValue)" }
}

#Preview {
  HomeView()
}
