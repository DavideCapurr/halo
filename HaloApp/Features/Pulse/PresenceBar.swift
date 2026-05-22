import SwiftUI
import HaloShared

/// Strip orizzontale in cima al Pulse feed con le persone che hanno una vibe
/// attiva. Tier-sorted (Inner prima). Non c'è nulla di "live"-vs-"dead":
/// presenza = avere una vibe nelle ultime 24h.
struct PresenceBar: View {
  let people: [DemoPerson]
  var onTap: (DemoPerson) -> Void = { _ in }

  private let bubbleSize: CGFloat = 44

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .top, spacing: 14) {
        ForEach(people) { p in
          Button { onTap(p) } label: {
            VStack(spacing: 6) {
              PresenceBubble(person: p, size: bubbleSize)
              Text(p.handle)
                .font(HaloType.ui(10, weight: .medium))
                .foregroundStyle(HaloInk.creamLow)
                .lineLimit(1)
            }
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 6)
    }
    .accessibilityLabel("Vibe attive")
  }
}

private struct PresenceBubble: View {
  let person: DemoPerson
  let size: CGFloat

  private var pulseSeed: UInt32 {
    var seed: UInt32 = 17
    for u in person.id.unicodeScalars { seed = seed &* 31 &+ u.value }
    return seed
  }

  var body: some View {
    ZStack {
      // pulsing aura per ogni vibe attiva
      TimelineView(.animation(minimumInterval: 1.0 / 24)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        // micro sfasamento per evitare che pulsino in fase
        let phase = sin((t / 3.2 + Double(pulseSeed % 100) / 100) * .pi * 2)
        Circle()
          .fill(
            RadialGradient(
              colors: [MoodPalette.auraRing(person.mood, alpha: 0.55), .clear],
              center: .center, startRadius: 0, endRadius: size * 0.95
            )
          )
          .frame(width: size * 1.4, height: size * 1.4)
          .opacity(0.55 + 0.20 * phase)
      }
      .allowsHitTesting(false)

      Circle()
        .fill(MoodPalette.auraColor(person.mood, l: 0.72))
        .frame(width: size, height: size)
        .shadow(color: MoodPalette.auraRing(person.mood, alpha: 0.55), radius: 6)
      PortraitView(personId: person.id, size: size - 4)
        .background(HaloTheme.portraitBacking, in: Circle())
    }
    .frame(width: size, height: size)
  }
}

#Preview {
  ZStack {
    Color.black
    PresenceBar(people: SeedPeople.all.filter(\.hasActiveVibe))
  }
  .frame(height: 90)
}
