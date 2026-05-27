import SwiftUI
import HaloShared

/// Central self bubble: same portrait/aura vocabulary as Pulse, just larger
/// and clearer. The plus badge is the only extra affordance.
struct SelfCenterView: View {
  let mood: Mood
  var size: CGFloat = 128
  var hasActiveVibe: Bool = true

  private var ringFill: Color {
    SwarmHaloTierState.connected.ringFill
  }

  private var moodAura: Color {
    hasActiveVibe ? MoodPalette.auraRing(mood, alpha: 0.34) : .clear
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
              colors: [moodAura, .clear],
              center: .center,
              startRadius: 0,
              endRadius: size * 1.12
            )
          )
          .frame(width: size * 1.95, height: size * 1.95)
          .opacity(hasActiveVibe ? 0.36 + 0.10 * phase : 0.16)
      }
      .allowsHitTesting(false)

      Circle()
        .fill(ringFill)
        .frame(width: size, height: size)
        .overlay(
          Circle().strokeBorder(SwarmHaloTierState.connected.stroke, lineWidth: 1)
        )
        .shadow(color: SwarmHaloTierState.connected.glow, radius: size * 0.18)

      PortraitView(personId: "self|hero", size: size - ringWidth * 2, grayscale: true)
        .background(HaloTheme.portraitBacking, in: Circle())

      Circle()
        .fill(MoodPalette.auraColor(mood, l: 0.82))
        .frame(width: max(10, size * 0.09), height: max(10, size * 0.09))
        .overlay(Circle().stroke(SwarmHalo.background, lineWidth: 1.8))
        .offset(x: size * 0.38, y: -size * 0.38)

      ZStack {
        Circle()
          .fill(SwarmHalo.ink)
          .overlay(Circle().stroke(SwarmHalo.background.opacity(0.80), lineWidth: 2))
          .shadow(color: SwarmHalo.absoluteBlack.opacity(0.38), radius: 6, y: 2)
        Image(systemName: "plus")
          .font(.system(size: size * 0.13, weight: .bold))
          .foregroundStyle(SwarmHalo.background)
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
    SwarmHalo.background
    HStack(spacing: 24) {
      SelfCenterView(mood: .chill, size: 128, hasActiveVibe: true)
      SelfCenterView(mood: .chill, size: 128, hasActiveVibe: false)
    }
  }
  .frame(width: 400, height: 300)
}
