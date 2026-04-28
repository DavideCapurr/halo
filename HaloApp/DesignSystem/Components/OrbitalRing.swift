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
    Circle()
      .stroke(
        active ? HaloTheme.ringActive : HaloTheme.ringInactive,
        style: StrokeStyle(lineWidth: active ? 0.7 : 0.5, dash: [3.5, 4])
      )
      .frame(width: diameter, height: diameter)
    .animation(.easeInOut(duration: 0.25), value: active)
    .accessibilityHidden(true)
  }
}
