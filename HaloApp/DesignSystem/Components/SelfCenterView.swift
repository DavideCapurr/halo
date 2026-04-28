import SwiftUI
import HaloShared

/// Central self bubble: same portrait/aura vocabulary as Pulse, just larger
/// and clearer. The plus badge is the only extra affordance.
struct SelfCenterView: View {
  let mood: Mood
  var size: CGFloat = 128
  var hasActiveVibe: Bool = true

  private var ringFill: Color {
    hasActiveVibe ? MoodPalette.auraColor(mood, l: 0.74) : HaloInk.creamHair
  }

  private var auraGlow: Color {
    hasActiveVibe ? MoodPalette.auraRing(mood, alpha: 0.58) : Color.white.opacity(0.12)
  }

  private var ringWidth: CGFloat { max(6, size * 0.07) }

  var body: some View {
    ZStack {
      TimelineView(.animation(minimumInterval: 1.0 / 18, paused: !hasActiveVibe)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / 4.2) * .pi * 2)
        Circle()
          .fill(
            RadialGradient(
              colors: [auraGlow, .clear],
              center: .center,
              startRadius: 0,
              endRadius: size * 1.12
            )
          )
          .frame(width: size * 1.95, height: size * 1.95)
          .opacity(hasActiveVibe ? 0.54 + 0.14 * phase : 0.22)
      }
      .allowsHitTesting(false)

      Circle()
        .fill(ringFill)
        .frame(width: size, height: size)
        .shadow(color: auraGlow, radius: hasActiveVibe ? size * 0.20 : 4)

      PortraitView(personId: "self|hero", size: size - ringWidth * 2)
        .background(HaloTheme.portraitBacking, in: Circle())

      Circle()
        .fill(MoodPalette.auraColor(mood, l: 0.82))
        .frame(width: max(10, size * 0.09), height: max(10, size * 0.09))
        .overlay(Circle().stroke(HaloInk.nightSurface, lineWidth: 1.8))
        .offset(x: size * 0.38, y: -size * 0.38)

      ZStack {
        Circle()
          .fill(HaloInk.cream)
          .overlay(Circle().stroke(HaloInk.nightSurface.opacity(0.80), lineWidth: 2))
          .shadow(color: .black.opacity(0.38), radius: 6, y: 2)
        Image(systemName: "plus")
          .font(.system(size: size * 0.13, weight: .bold))
          .foregroundStyle(Color.black)
      }
      .frame(width: size * 0.27, height: size * 0.27)
      .offset(x: size * 0.36, y: size * 0.36)
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
