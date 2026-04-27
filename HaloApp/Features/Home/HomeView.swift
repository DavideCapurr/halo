import SwiftUI
import HaloShared

/// Schermata principale: background Deep Space + TopBar + OrbitalField + BottomBar
/// + sheets (peek / vibe setter / tier confirm).
/// Per ora usa `SeedPeople` come dataset; verrà sostituita da HomeViewModel + Supabase
/// quando gli step 4-8 saranno integrati.
struct HomeView: View {
  @State private var me: DemoPerson = SeedPeople.me
  @State private var people: [DemoPerson] = SeedPeople.all + SeedPeople.asteroids
  @State private var peek: DemoPerson? = nil
  @State private var showVibeSetter: Bool = false
  @State private var pendingProposal: TierConfirmationSheet.Proposal? = nil
  @State private var fieldZoom: ZoomLevel = .full

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

        OrbitalFieldView(
          people: people,
          me: me,
          pulsing: true,
          onBubbleTap: { peek = $0 },
          onSelfTap: { showVibeSetter = true },
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

        BottomBarView(
          selfMood: me.mood,
          onCompose: { showVibeSetter = true }
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
}

extension TierConfirmationSheet.Proposal: Identifiable {
  var id: String { "\(person.id)-\(from.rawValue)-\(to.rawValue)" }
}

#Preview {
  HomeView()
}
