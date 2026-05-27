import SwiftUI
import HaloShared

/// Hairline dashed ring per un tier. Quasi invisibile a riposo (opacity 0.07);
/// si illumina quando il drag-to-tier passa sopra (opacity 0.42).
struct OrbitalRing: View {
  let tier: FriendshipTier
  let diameter: CGFloat
  var count: Int = 0
  var active: Bool = false

  var body: some View {
    let state = tier.swarmHaloState
    ZStack {
      Circle()
        .stroke(
          active ? state.activeStroke : HaloInk.creamLine,
          style: StrokeStyle(lineWidth: active ? 0.8 : 0.5, dash: [3.5, 5.5])
        )
        .frame(width: diameter, height: diameter)

      if active || tier == .inner {
        Text("\(tier.label.lowercased()) \(String(format: "%02d", count))")
          .haloEyebrow(active ? state.accent : HaloInk.creamMute, size: 7.5, tracking: 1.7)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Capsule().fill(active ? state.badgeFill : HaloInk.creamWhisper))
          .overlay(Capsule().strokeBorder(active ? state.activeStroke : HaloInk.creamLine, lineWidth: 0.5))
          .offset(y: -diameter / 2)
      }
    }
    .animation(SwarmHalo.easeSwarm(0.25), value: active)
    .accessibilityHidden(true)
  }
}
