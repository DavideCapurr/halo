import SwiftUI
import HaloShared

/// Schermata principale: background Deep Space + TopBar + (OrbitalField | PulseFeed) + BottomBar
/// + sheets (peek / vibe setter / tier confirm).
/// Switch tra le due viste tramite swipe orizzontale o pulsanti dedicati nella BottomBar.
struct HomeView: View {
  enum Mode { case field, pulse }

  @State private var me: DemoPerson = SeedPeople.me
  @State private var people: [DemoPerson] = SeedPeople.all + SeedPeople.asteroids
  @State private var peek: DemoPerson? = nil
  @State private var showVibeSetter: Bool = false
  @State private var pendingProposal: TierConfirmationSheet.Proposal? = nil
  @State private var fieldZoom: ZoomLevel = .full
  @State private var mode: Mode = .field
  @State private var showCompose: Bool = false

  /// Conteggio dei tier delle proprie cerchie per il `VibeFirstComposeView`.
  private var tierCounts: [FriendshipTier: Int] {
    Dictionary(grouping: people.filter(\.isMutual), by: \.tier).mapValues(\.count)
  }

  private var asteroids: [DemoPerson] { people.filter { !$0.isMutual } }

  var body: some View {
    ZStack {
      DeepSpaceBackground()

      VStack(spacing: 0) {
        TopBarView(
          mood: me.mood,
          onVibeTap: { showVibeSetter = true },
          onSearchTap: {}
        )
        .padding(.top, 8)

        ZStack {
          if mode == .field {
            fieldArea
              .transition(.asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
              ))
          } else {
            PulseFeedView(onPersonTap: { peek = $0 })
              .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
              ))
          }
        }
        .frame(maxHeight: .infinity)
        .gesture(modeSwipeGesture)

        BottomBarView(
          selfMood: me.mood,
          onCompose: { showCompose = true },
          onOrbit: { withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { mode = .field } },
          onPulse: { withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { mode = .pulse } }
        )
        .padding(.bottom, 16)
      }
      .padding(.top, 4)
      .animation(.easeInOut(duration: 0.30), value: fieldZoom)
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
          pendingProposal = .init(person: person, from: person.tier, to: toTier)
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

  // MARK: - swipe between modes

  private var modeSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 22)
      .onEnded { value in
        let dx = value.translation.width
        let dy = value.translation.height
        // Solo gesti prevalentemente orizzontali, abbastanza ampi.
        guard abs(dx) > abs(dy) * 1.5, abs(dx) > 60 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
          if dx < 0, mode == .field { mode = .pulse }
          else if dx > 0, mode == .pulse { mode = .field }
        }
      }
  }
}

extension TierConfirmationSheet.Proposal: Identifiable {
  var id: String { "\(person.id)-\(from.rawValue)-\(to.rawValue)" }
}

#Preview {
  HomeView()
}
