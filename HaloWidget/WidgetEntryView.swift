import SwiftUI
import WidgetKit
import HaloShared

/// Render del widget Halo.
/// - `.accessoryCircular`: mini orbital field con 6 bolle radiali su un anello.
/// - `.accessoryRectangular`: 4 bolle inline + count totale.
/// - `.systemMedium` (StandBy): hero center + anello esterno bolle, deep space.
struct WidgetEntryView: View {
  let entry: HaloEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .accessoryCircular:
      circularBody
    case .accessoryRectangular:
      rectangularBody
    case .systemMedium:
      standByMediumBody
    default:
      standByMediumBody
    }
  }

  // MARK: - Lockscreen circular

  private var circularBody: some View {
    let bubbles = Array(entry.snapshot.bubbles.prefix(6))
    return ZStack {
      Circle().strokeBorder(.white.opacity(0.30), style: .init(lineWidth: 0.6, dash: [2, 2]))
      ForEach(Array(bubbles.enumerated()), id: \.offset) { (i, b) in
        let angle = Double(i) * (2 * .pi / Double(max(bubbles.count, 1))) - .pi / 2
        Circle()
          .fill(bubbleColor(for: b))
          .frame(width: 7, height: 7)
          .position(
            x: 28 + cos(angle) * 18,
            y: 28 + sin(angle) * 18
          )
      }
      Text("\(entry.snapshot.bubbles.count)")
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
    }
    .frame(width: 56, height: 56)
  }

  // MARK: - Lockscreen rectangular

  private var rectangularBody: some View {
    HStack(spacing: 4) {
      ForEach(entry.snapshot.bubbles.prefix(4), id: \.userId) { b in
        Circle()
          .fill(bubbleColor(for: b))
          .frame(width: 14, height: 14)
          .overlay(
            Text(String(b.handle.prefix(1)))
              .font(.system(size: 8, weight: .bold))
              .foregroundStyle(.black.opacity(0.7))
          )
      }
      if entry.snapshot.bubbles.count > 4 {
        Text("+\(entry.snapshot.bubbles.count - 4)")
          .font(.system(size: 11, weight: .medium, design: .monospaced))
          .foregroundStyle(.white.opacity(0.75))
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - StandBy systemMedium

  private var standByMediumBody: some View {
    ZStack {
      // Deep space background
      LinearGradient(
        colors: [Color.black, Color(red: 12/255, green: 10/255, blue: 18/255)],
        startPoint: .top, endPoint: .bottom
      )
      .ignoresSafeArea()

      GeometryReader { geo in
        let cx = geo.size.width / 2
        let cy = geo.size.height / 2
        let r = min(geo.size.width, geo.size.height) * 0.40

        Circle()
          .strokeBorder(.white.opacity(0.10), style: .init(lineWidth: 0.5, dash: [3, 3]))
          .frame(width: r * 2, height: r * 2)
          .position(x: cx, y: cy)

        // hero center (ipotetico self)
        Circle()
          .fill(Color.white.opacity(0.35))
          .frame(width: 26, height: 26)
          .shadow(color: .white.opacity(0.4), radius: 6)
          .position(x: cx, y: cy)

        let ring = Array(entry.snapshot.bubbles.prefix(8))
        ForEach(Array(ring.enumerated()), id: \.offset) { (i, b) in
          let angle = Double(i) * (2 * .pi / Double(max(ring.count, 1))) - .pi / 2
          Circle()
            .fill(bubbleColor(for: b))
            .frame(width: 16, height: 16)
            .shadow(color: bubbleGlow(for: b), radius: 4)
            .position(x: cx + cos(angle) * r, y: cy + sin(angle) * r)
        }

        // Footer count
        Text("\(entry.snapshot.bubbles.count) bolle")
          .font(.system(size: 10, weight: .medium, design: .monospaced))
          .foregroundStyle(.white.opacity(0.55))
          .position(x: cx, y: geo.size.height - 14)
      }
    }
  }

  // MARK: - color helpers

  private func bubbleColor(for b: WidgetSnapshot.Bubble) -> Color {
    if let hex = b.colorHex, !hex.isEmpty {
      return Color(hex: hex)
    }
    if let mood = b.mood {
      return Color(hex: mood.defaultHex)
    }
    return Color.white.opacity(0.35)
  }

  private func bubbleGlow(for b: WidgetSnapshot.Bubble) -> Color {
    bubbleColor(for: b).opacity(0.55)
  }
}

private extension Color {
  init(hex: String) {
    var h = hex
    if h.hasPrefix("#") { h.removeFirst() }
    guard h.count == 6, let v = UInt32(h, radix: 16) else {
      self = .white
      return
    }
    let r = Double((v >> 16) & 0xFF) / 255.0
    let g = Double((v >>  8) & 0xFF) / 255.0
    let b = Double( v        & 0xFF) / 255.0
    self = Color(red: r, green: g, blue: b)
  }
}
