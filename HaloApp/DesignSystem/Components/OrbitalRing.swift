import SwiftUI
import HaloShared

/// Step 3: singolo anello tier, disegnato via Canvas con stroke sottile.
/// Usato 4 volte dentro `OrbitalFieldView` (uno per tier).
struct OrbitalRing: View {
  let tier: FriendshipTier
  let diameter: CGFloat

  var body: some View {
    Circle()
      .strokeBorder(HaloTheme.ringStroke, lineWidth: 0.8)
      .frame(width: diameter, height: diameter)
      .accessibilityHidden(true)
  }
}
