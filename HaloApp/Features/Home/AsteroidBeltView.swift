import SwiftUI
import HaloShared

/// Cintura di asteroidi oltre l'anello Nebula. Bolle piccole non strutturate,
/// con micro-drift orizzontale e verticale lento. Visibile solo a zoom `.asteroids`.
/// Pan orizzontale per esplorare quando la cintura è lunga.
struct AsteroidBeltView: View {
  let people: [DemoPerson]
  /// Categoria opzionale: se vuota → cintura monolitica; se valorizzata → header pill.
  var groupBy: ((DemoPerson) -> String)? = nil
  var onTap: (DemoPerson) -> Void = { _ in }

  private let bubbleSize: CGFloat = 28

  var body: some View {
    let groups = makeGroups(people: people)
    return ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .center, spacing: 18) {
        ForEach(groups, id: \.title) { group in
          VStack(spacing: 6) {
            HStack(spacing: 8) {
              ForEach(group.items) { p in
                AsteroidBubble(person: p, size: bubbleSize)
                  .onTapGesture { onTap(p) }
              }
            }
            if let title = group.title.isEmpty ? nil : group.title {
              Text(title)
                .haloEyebrow(HaloInk.creamMute, size: 8, tracking: 1.8)
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
    }
    .frame(height: bubbleSize + 38)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
    )
    .padding(.horizontal, 14)
    .accessibilityLabel("Asteroidi: account asimmetrici")
  }

  // MARK: - Grouping

  private struct AsteroidGroup { let title: String; let items: [DemoPerson] }

  private func makeGroups(people: [DemoPerson]) -> [AsteroidGroup] {
    guard let groupBy else { return [.init(title: "", items: people)] }
    let dict = Dictionary(grouping: people, by: groupBy)
    return dict.keys.sorted().map { key in
      AsteroidGroup(title: key, items: dict[key] ?? [])
    }
  }
}

/// Bolla "asteroide": piccola, drift animato, non interattiva oltre il tap.
private struct AsteroidBubble: View {
  let person: DemoPerson
  let size: CGFloat

  /// Seed deterministico per evitare che tutti gli asteroidi pulsino in fase.
  private var seed: Double {
    var h: UInt32 = 5381
    for u in person.id.unicodeScalars { h = h &* 33 &+ u.value }
    return Double(h % 1000) / 1000.0
  }

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 24)) { ctx in
      let t = ctx.date.timeIntervalSinceReferenceDate
      // Drift molto lento, ampiezza piccola.
      let dx = CGFloat(sin((t / (8.0 + seed * 4)) * .pi * 2)) * 4
      let dy = CGFloat(cos((t / (10.0 + seed * 4)) * .pi * 2)) * 3
      ZStack {
        Circle()
          .fill(person.hasActiveVibe
                ? MoodPalette.auraColor(person.mood, l: 0.62)
                : Color.white.opacity(0.18))
          .frame(width: size, height: size)
          .shadow(
            color: person.hasActiveVibe
              ? MoodPalette.auraRing(person.mood, alpha: 0.45)
              : .clear,
            radius: 5
          )
        PortraitView(personId: person.id, size: size - 4)
          .background(HaloTheme.portraitBacking, in: Circle())
      }
      .offset(x: dx, y: dy)
    }
    .frame(width: size, height: size)
    .accessibilityLabel(person.handle)
  }
}

#Preview {
  ZStack {
    Color.black
    AsteroidBeltView(people: SeedPeople.asteroids)
  }
  .frame(height: 80)
}
