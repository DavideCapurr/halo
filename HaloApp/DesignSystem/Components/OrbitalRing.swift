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
    ZStack {
      Circle()
        .stroke(
          active ? HaloInk.cream.opacity(0.46) : HaloInk.creamLine,
          style: StrokeStyle(lineWidth: active ? 0.6 : 0.4)
        )
        .frame(width: diameter, height: diameter)

      Text("\(tier.label)  ·  \(String(format: "%02d", count))")
        .font(HaloType.mono(8.5, weight: .medium))
        .kerning(2.6)
        .textCase(.uppercase)
        .foregroundStyle(active ? HaloInk.cream : HaloInk.creamMute)
        .lineLimit(1)
        .fixedSize()
        .offset(x: -diameter / 2 - 10)
    }
    .frame(width: diameter, height: diameter)
    .animation(.easeInOut(duration: 0.25), value: active)
    .accessibilityHidden(true)
  }
}
