import SwiftUI
import HaloShared

/// Bolla portrait-first del design Deep Space. Layer dall'esterno verso l'interno:
///  1. ambient aura glow (radial gradient, intensità = decay del post)
///  2. ring colorato (vibe color se attiva, neutro altrimenti); pulsa solo se vibe attiva
///  3. portrait disc clippato a cerchio
///  4. dot bianco "Adesso" se ha postato negli ultimi 30 min
///  5. label handle sotto (solo Inner/Close)
struct BubbleView: View {
  let personId: String
  let handle: String
  let mood: Mood
  let size: CGFloat
  /// Mostra il pallino "Adesso" in alto a destra: post < 30 min.
  var hasNew: Bool = false
  /// Mostra `@handle` sotto la bolla (solo per Inner/Close).
  var showName: Bool = false
  /// Animazione di pulsazione abilitata globalmente.
  var pulsing: Bool = true
  /// True se la persona ha una vibe attiva (ultime 24h). Se false → ring neutro.
  var hasActiveVibe: Bool = true
  /// Quanto fa è stato pubblicato l'ultimo post; alimenta il glow decay (72h max).
  var lastPostAt: Date? = nil

  private var ringWidth: CGFloat { max(2.5, size * 0.045) }

  /// Tinta vibe se attiva, altrimenti grigio caldo neutro.
  private var ringColor: Color {
    hasActiveVibe ? MoodPalette.auraColor(mood, l: 0.72) : Color.white.opacity(0.18)
  }
  private var ringGlow: Color {
    hasActiveVibe ? MoodPalette.auraRing(mood, alpha: 0.55) : Color.white.opacity(0.10)
  }

  /// Decay 0..1 del glow: 1 = appena postato, 0 = ≥ 72h fa o nessun post.
  private var glowDecay: Double {
    guard let t = lastPostAt else { return 0 }
    let age = Date.now.timeIntervalSince(t)
    let window: TimeInterval = 72 * 3600
    let v = (window - age) / window
    return min(max(v, 0), 1)
  }

  /// "Adesso" = post negli ultimi 30 min (priorità sul flag esterno hasNew).
  private var isAdesso: Bool {
    if let t = lastPostAt, Date.now.timeIntervalSince(t) <= 30 * 60 { return true }
    return hasNew
  }

  var body: some View {
    ZStack {
      // 1. ambient aura glow — intensità = glowDecay; pulsa solo se vibe attiva
      TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !(pulsing && hasActiveVibe))) { ctx in
        let period = 3.0 + Double(Int(size) % 3)
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / period) * .pi * 2)
        let pulseOpacity = (pulsing && hasActiveVibe) ? (0.55 + 0.20 * phase) : 0.55
        // Mix tra "ring glow vibe" (forte se attiva) e decay del post.
        let baseFloor: Double = hasActiveVibe ? 0.35 : 0.15
        let postBoost: Double = 0.65 * glowDecay
        let opacity = pulseOpacity * (baseFloor + postBoost)
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
          .opacity(opacity)
      }
      .allowsHitTesting(false)

      // 2 + 3. ring + portrait
      ZStack {
        Circle()
          .fill(ringColor)
          .frame(width: size, height: size)
          .shadow(color: ringGlow, radius: size * 0.20 * (0.6 + 0.4 * glowDecay))

        PortraitView(personId: personId, size: size - ringWidth * 2)
          .background(HaloTheme.portraitBacking, in: Circle())
      }

      // 4. "Adesso" indicator
      if isAdesso {
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
      BubbleView(personId: "p01", handle: "gia",  mood: .warm,    size: 96, hasNew: true, showName: true,
                 hasActiveVibe: true, lastPostAt: .now.addingTimeInterval(-15 * 60))
      BubbleView(personId: "p07", handle: "nico", mood: .chill,   size: 72, showName: true,
                 hasActiveVibe: false, lastPostAt: .now.addingTimeInterval(-50 * 3600))
      BubbleView(personId: "p18", handle: "anais",mood: .soft,    size: 52,
                 hasActiveVibe: true,  lastPostAt: nil)
      BubbleView(personId: "p29", handle: "eva",  mood: .blue,    size: 38,
                 hasActiveVibe: false, lastPostAt: nil)
    }
  }
  .frame(width: 400, height: 200)
}
