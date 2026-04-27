import SwiftUI
import HaloShared

/// Self center: portrait con anello vibe + doppio halo (uno blurred, uno netto)
/// + badge "+" bianco bottom-right per aprire il vibe setter.
/// Se `hasActiveVibe == false` il ring va in tonalità neutra e gli halo non pulsano.
struct SelfCenterView: View {
  let mood: Mood
  var size: CGFloat = 128
  var hasActiveVibe: Bool = true

  private var ringColor: Color {
    hasActiveVibe ? MoodPalette.auraColor(mood, l: 0.78) : Color.white.opacity(0.20)
  }
  private var ringGlow: Color {
    hasActiveVibe ? MoodPalette.auraRing(mood, alpha: 0.65) : Color.white.opacity(0.12)
  }
  private var ringWidth: CGFloat { max(3.5, size * 0.05) }

  var body: some View {
    ZStack {
      // outer breathing halo (large, blurred) — anima solo se vibe attiva
      TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !hasActiveVibe)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / 4.5) * .pi * 2)
        let scale = hasActiveVibe ? (1.0 + 0.04 * phase) : 1.0
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
          .blur(radius: 6)
          .scaleEffect(scale)
          .opacity(hasActiveVibe ? 0.95 : 0.55)
      }
      .allowsHitTesting(false)

      // mid halo (compact, no blur)
      Circle()
        .fill(
          RadialGradient(
            colors: [hasActiveVibe ? MoodPalette.auraRing(mood, alpha: 0.4) : Color.white.opacity(0.08), .clear],
            center: .center,
            startRadius: 0,
            endRadius: size * 0.75
          )
        )
        .frame(width: size * 1.7, height: size * 1.7)
        .allowsHitTesting(false)

      // ring + portrait
      ZStack {
        Circle()
          .fill(ringColor)
          .frame(width: size, height: size)
          .shadow(color: ringGlow, radius: size * 0.30)

        PortraitView(personId: "self|hero", size: size - ringWidth * 2)
          .background(HaloTheme.portraitBacking, in: Circle())
      }

      // "+" badge bottom-right
      ZStack {
        Circle().fill(Color.white)
          .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 2))
          .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
        Image(systemName: "plus")
          .font(.system(size: size * 0.13, weight: .bold))
          .foregroundStyle(Color.black)
      }
      .frame(width: size * 0.28, height: size * 0.28)
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
