import SwiftUI
import HaloShared

/// Orbit bubble aligned to the Pulse visual language: real portrait, mood aura,
/// clear activity dot, optional name label. It should read as a person first,
/// not as an abstract planet.
struct BubbleView: View {
  let personId: String
  let handle: String
  let mood: Mood
  let size: CGFloat
  var tier: FriendshipTier = .orbit
  var hasNew: Bool = false
  var showName: Bool = false
  var pulsing: Bool = true
  var hasActiveVibe: Bool = true
  var lastPostAt: Date? = nil

  private var ringWidth: CGFloat { max(3, size * 0.075) }

  private var ringFill: Color {
    tier.swarmHaloState.ringFill
  }

  private var moodAura: Color {
    hasActiveVibe ? MoodPalette.auraRing(mood, alpha: 0.30) : .clear
  }

  private var isAdesso: Bool {
    if let t = lastPostAt, Date.now.timeIntervalSince(t) <= 30 * 60 { return true }
    return hasNew
  }

  var body: some View {
    ZStack {
      TimelineView(.animation(minimumInterval: 1.0 / 18, paused: !(pulsing && hasActiveVibe))) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / 3.4) * .pi * 2)
        let opacity = hasActiveVibe ? (0.28 + 0.10 * phase) : 0.12
        Circle()
          .fill(
            RadialGradient(
              colors: [moodAura, .clear],
              center: .center,
              startRadius: 0,
              endRadius: size * 0.90
            )
          )
          .frame(width: size * 1.44, height: size * 1.44)
          .opacity(opacity)
      }
      .allowsHitTesting(false)

      Circle()
        .fill(ringFill)
        .frame(width: size, height: size)
        .overlay(
          Circle().strokeBorder(tier.swarmHaloState.stroke, lineWidth: tier == .nebula ? 0.5 : 1)
        )
        .shadow(color: tier.swarmHaloState.glow, radius: size * 0.14)

      PortraitView(personId: personId, size: size - ringWidth * 2, grayscale: true)
        .background(HaloTheme.portraitBacking, in: Circle())

      Circle()
        .fill(MoodPalette.auraColor(mood, l: 0.78))
        .frame(width: max(8, size * 0.14), height: max(8, size * 0.14))
        .overlay(Circle().stroke(SwarmHalo.background, lineWidth: 1.5))
        .opacity(hasActiveVibe ? 1 : 0.42)
        .offset(x: size * 0.38, y: -size * 0.38)

      if isAdesso {
        Circle()
          .fill(SwarmHalo.ink)
          .frame(width: max(10, size * 0.16), height: max(10, size * 0.16))
          .overlay(Circle().stroke(SwarmHalo.background.opacity(0.85), lineWidth: 2))
          .shadow(color: SwarmHalo.ink.opacity(0.68), radius: 5)
          .offset(x: -size * 0.38, y: -size * 0.38)
      }

      if showName {
        Text("@\(handle)")
          .font(HaloType.mono(max(8, size * 0.105), weight: .medium))
          .kerning(0.9)
          .textCase(.uppercase)
          .foregroundStyle(HaloInk.creamLow)
          .lineLimit(1)
          .fixedSize()
          .padding(.horizontal, 7)
          .padding(.vertical, 3)
          .background(Capsule().fill(tier.swarmHaloState.badgeFill))
          .overlay(Capsule().strokeBorder(tier.swarmHaloState.stroke, lineWidth: 0.5))
          .offset(y: size * 0.5 + 13)
      }
    }
    .frame(width: size, height: size)
  }
}

#Preview {
  ZStack {
    SwarmHalo.background
    HStack(spacing: 30) {
      BubbleView(personId: "p01", handle: "gia", mood: .warm, size: 96, hasNew: true, showName: true,
                 hasActiveVibe: true, lastPostAt: .now.addingTimeInterval(-15 * 60))
      BubbleView(personId: "p07", handle: "nico", mood: .chill, size: 72, showName: true,
                 hasActiveVibe: false, lastPostAt: .now.addingTimeInterval(-50 * 3600))
      BubbleView(personId: "p18", handle: "anais", mood: .soft, size: 52,
                 hasActiveVibe: true, lastPostAt: nil)
    }
  }
  .frame(width: 400, height: 200)
}
