import SwiftUI
import HaloShared

/// Pulse feed: scroll verticale tier-sorted.
/// Header: PresenceBar (vibe attive). Sezione "Adesso" (post < 30 min) in cima.
/// Sezioni leggere: "Inner & Close", "Orbit", "Nebula".
/// Sfondo deep-space prende leggera tinta dal mood dominante delle prime card.
struct PulseFeedView: View {
  @State private var vm = FeedViewModel()
  /// Tap su una card → apri HaloSpace della persona.
  var onPersonTap: (DemoPerson) -> Void = { _ in }

  var body: some View {
    ZStack {
      // Sfondo: deep-space + tinta soft del mood dominante.
      DeepSpaceBackground()
      if let dominant = vm.dominantMood() {
        LinearGradient(
          colors: [
            MoodPalette.auraRing(dominant, alpha: 0.10),
            .clear
          ],
          startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: dominant)
      }

      ScrollView {
        LazyVStack(spacing: 14, pinnedViews: [.sectionHeaders]) {
          if !vm.presenceItems.isEmpty {
            PresenceBar(people: vm.presenceItems, onTap: onPersonTap)
              .padding(.top, 4)
          }

          // Sezione "Adesso" (in testa, solo se ha contenuti < 30 min).
          if !vm.adessoItems.isEmpty {
            Section {
              ForEach(vm.adessoItems) { p in
                MomentCard(person: p, onTap: { onPersonTap(p) })
                  .padding(.horizontal, 14)
                  .transition(.asymmetric(
                    insertion: .scale(scale: 0.92).combined(with: .opacity),
                    removal: .opacity
                  ))
              }
            } header: {
              feedSectionHeader(title: "Adesso", warm: true)
            }
          }

          ForEach(vm.sections, id: \.0) { (section, items) in
            Section {
              ForEach(items) { p in
                MomentCard(person: p, onTap: { onPersonTap(p) })
                  .padding(.horizontal, 14)
              }
            } header: {
              feedSectionHeader(title: section.title)
            }
          }
        }
        .padding(.bottom, 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: vm.adessoItems.map(\.id))
      }
      .scrollIndicators(.hidden)
    }
    .task { await vm.load() }
  }

  // MARK: - section header

  @ViewBuilder
  private func feedSectionHeader(title: String, warm: Bool = false) -> some View {
    HStack {
      Text(title)
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .kerning(0.6)
        .textCase(.uppercase)
        .foregroundStyle(warm
          ? MoodPalette.auraColor(.warm, l: 0.78)
          : Color.white.opacity(0.55))
      Rectangle()
        .fill(Color.white.opacity(0.08))
        .frame(height: 0.5)
    }
    .padding(.horizontal, 18)
    .padding(.top, 8)
    .padding(.bottom, 4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      LinearGradient(
        colors: [Color.black.opacity(0.55), Color.black.opacity(0.0)],
        startPoint: .top, endPoint: .bottom
      )
    )
  }
}

#Preview {
  PulseFeedView()
    .preferredColorScheme(.dark)
}
