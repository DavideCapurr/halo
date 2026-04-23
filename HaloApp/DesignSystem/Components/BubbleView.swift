import SwiftUI
import HaloShared

/// Step 3: bolla con aura pulsante. Accetta color hex dalla vibe.
/// L'alone è gradient radiale; la pulsazione è guidata da TimelineView in OrbitalFieldView.
struct BubbleView: View {
  let handle: String
  let colorHex: String?
  let size: CGFloat
  let pulsePhase: Double   // 0…1 dal TimelineView genitore

  private var color: Color {
    Color(hex: colorHex ?? "#9B9B9B")
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(color.opacity(0.22 + 0.12 * sin(pulsePhase * .pi * 2)))
        .blur(radius: size * 0.4)
        .frame(width: size * 2.2, height: size * 2.2)

      Circle()
        .fill(color)
        .frame(width: size, height: size)

      Text(String(handle.prefix(1)).uppercased())
        .font(.system(size: size * 0.45, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
    }
    .accessibilityLabel(handle)
  }
}
