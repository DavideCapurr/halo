import SwiftUI
import HaloShared

/// Bolla portrait-first del design Deep Space. Layer dall'esterno verso l'interno:
///  1. ambient aura glow (radial gradient, pulsante)
///  2. ring colorato (vibe color), padding `ringWidth`
///  3. portrait disc clippato a cerchio
///  4. dot bianco "new" in alto a destra
///  5. label handle sotto (solo Inner/Close)
struct BubbleView: View {
  let personId: String
  let handle: String
  let mood: Mood
  let size: CGFloat
  /// Mostra il pallino "post nuovo" in alto a destra.
  var hasNew: Bool = false
  /// Mostra `@handle` sotto la bolla (solo per Inner/Close).
  var showName: Bool = false
  /// Dimensione tier corrente, usata per ricavare un periodo di pulsazione vario tra bolle.
  var pulsing: Bool = true

  private var ringWidth: CGFloat { max(2.5, size * 0.045) }
  private var ringColor: Color   { MoodPalette.auraColor(mood, l: 0.72) }
  private var ringGlow: Color    { MoodPalette.auraRing(mood, alpha: 0.55) }

  var body: some View {
    ZStack {
      // 1. ambient aura glow — soft radial pulse
      TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !pulsing)) { ctx in
        let period = 3.0 + Double(Int(size) % 3)
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / period) * .pi * 2)
        let opacity = 0.55 + 0.20 * phase
        Circle()
          .fill(
            RadialGradient(
              colors: [ringGlow, .clear],
              center: .center,
              startRadius: 0,
              endRadius: size * 0.95
            )
          )
          .frame(width: size * 1.44, height: size * 1.44)
          .opacity(pulsing ? opacity : 0.55)
      }
      .allowsHitTesting(false)

      // 2 + 3. ring + portrait
      ZStack {
        Circle()
          .fill(ringColor)
          .frame(width: size, height: size)
          .shadow(color: ringGlow, radius: size * 0.20)

        PortraitView(personId: personId, size: size - ringWidth * 2)
          .background(HaloTheme.portraitBacking, in: Circle())
      }

      // 4. new post indicator
      if hasNew {
        Circle()
          .fill(Color.white)
          .frame(width: max(12, size * 0.18), height: max(12, size * 0.18))
          .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 2))
          .shadow(color: .white.opacity(0.9), radius: 5)
          .offset(x: size * 0.42, y: -size * 0.42)
      }

      // 5. handle label
      if showName {
        Text(handle)
          .font(.system(size: max(10, size * 0.12), weight: .medium, design: .rounded))
          .kerning(-0.1)
          .foregroundStyle(Color.white.opacity(0.75))
          .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
          .lineLimit(1)
          .fixedSize()
          .offset(y: size * 0.5 + 12)
      }
    }
    .frame(width: size, height: size)
  }
}

#Preview {
  ZStack {
    Color.black
    HStack(spacing: 30) {
      BubbleView(personId: "p01", handle: "gia",  mood: .warm,    size: 96, hasNew: true,  showName: true)
      BubbleView(personId: "p07", handle: "nico", mood: .chill,   size: 72, showName: true)
      BubbleView(personId: "p18", handle: "anais",mood: .soft,    size: 52)
      BubbleView(personId: "p29", handle: "eva",  mood: .blue,    size: 38)
    }
  }
  .frame(width: 400, height: 200)
}
