import SwiftUI
import HaloShared

/// Self center v2: tile editoriale più grande, halo bronzo controllato e
/// micro-dot mood. Il "+" resta un gesto, non una decorazione colorata.
struct SelfCenterView: View {
  let mood: Mood
  var size: CGFloat = 128
  var hasActiveVibe: Bool = true

  private var ringGlow: Color {
    hasActiveVibe ? HaloInk.bronzeGlow : Color.white.opacity(0.10)
  }

  var body: some View {
    ZStack {
      TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !hasActiveVibe)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / 5.8) * .pi * 2)
        let scale = hasActiveVibe ? (1.0 + 0.025 * phase) : 1.0
        Circle()
          .fill(
            RadialGradient(
              colors: [ringGlow, .clear],
              center: .center,
              startRadius: 0,
              endRadius: size * 1.15
            )
          )
          .frame(width: size * 2.8, height: size * 2.8)
          .blur(radius: 10)
          .scaleEffect(scale)
          .opacity(hasActiveVibe ? 0.54 : 0.26)
      }
      .allowsHitTesting(false)

      Circle()
        .fill(
          RadialGradient(
            colors: [HaloInk.cream.opacity(hasActiveVibe ? 0.10 : 0.05), .clear],
            center: .center,
            startRadius: 0,
            endRadius: size * 0.75
          )
        )
        .frame(width: size * 1.7, height: size * 1.7)
        .allowsHitTesting(false)

      MonogramTile(
        letter: "tu",
        spec: MonogramTileSpec(id: "self|hero"),
        size: size,
        ringTone: .hero
      )

      Circle()
        .fill(MoodPalette.auraColor(mood, l: hasActiveVibe ? 0.74 : 0.46))
        .frame(width: max(8, size * 0.08), height: max(8, size * 0.08))
        .overlay(Circle().stroke(HaloInk.nightSurface, lineWidth: 1.2))
        .shadow(color: MoodPalette.auraRing(mood, alpha: hasActiveVibe ? 0.32 : 0.0), radius: 3)
        .opacity(hasActiveVibe ? 0.95 : 0.45)
        .offset(x: size * 0.41, y: -size * 0.41)

      ZStack {
        Circle()
          .fill(HaloInk.cream)
          .overlay(Circle().stroke(Color.black.opacity(0.55), lineWidth: 1.5))
          .shadow(color: .black.opacity(0.45), radius: 6, y: 2)
        Image(systemName: "plus")
          .font(.system(size: size * 0.12, weight: .semibold))
          .foregroundStyle(Color.black)
      }
      .frame(width: size * 0.25, height: size * 0.25)
      .offset(x: size * 0.39, y: size * 0.39)
    }
    .frame(width: size, height: size)
    .contentShape(Circle())
  }
}

#Preview {
  ZStack {
    Color.black
    HStack(spacing: 24) {
      SelfCenterView(mood: .chill, size: 128, hasActiveVibe: true)
      SelfCenterView(mood: .chill, size: 128, hasActiveVibe: false)
    }
  }
  .frame(width: 400, height: 300)
}
