import SwiftUI
import WidgetKit
import HaloShared

private enum WidgetSwarm {
  static let absoluteBlack = Color.black
  static let field = Color(red: 0.01, green: 0.01, blue: 0.012)
  static let surface = Color(red: 0.91, green: 0.91, blue: 0.92).opacity(0.08)
  static let platinum = Color(red: 0.91, green: 0.91, blue: 0.92)
  static let line = platinum.opacity(0.16)
  static let hair = platinum.opacity(0.08)
  static let connected = Color(red: 184/255, green: 1, blue: 0)
  static let operational = Color(red: 123/255, green: 43/255, blue: 1)
  static let attention = Color(red: 1, green: 43/255, blue: 184/255)
}

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

  private var circularBubbles: [WidgetSnapshot.Bubble] {
    Array(entry.snapshot.bubbles.prefix(6))
  }

  private var circularBody: some View {
    ZStack {
      Circle().strokeBorder(WidgetSwarm.line, style: .init(lineWidth: 0.6, dash: [2, 3]))
      Circle().strokeBorder(WidgetSwarm.connected.opacity(0.55), lineWidth: 0.8)
        .frame(width: 34, height: 34)
      ForEach(Array(circularBubbles.enumerated()), id: \.offset) { index, bubble in
        CircularWidgetBubble(
          color: bubbleColor(for: bubble),
          index: index,
          total: circularBubbles.count
        )
      }
      Text("\(entry.snapshot.bubbles.count)")
        .font(.system(size: 13, weight: .semibold, design: .monospaced))
        .foregroundStyle(WidgetSwarm.platinum)
    }
    .frame(width: 56, height: 56)
  }

  // MARK: - Lockscreen rectangular

  private var rectangularBody: some View {
    HStack(spacing: 6) {
      Text("HALO")
        .font(.system(size: 9, weight: .semibold, design: .monospaced))
        .foregroundStyle(WidgetSwarm.platinum.opacity(0.62))
      ForEach(entry.snapshot.bubbles.prefix(4), id: \.userId) { b in
        RectangularWidgetBubble(color: bubbleColor(for: b), handle: b.handle)
      }
      if entry.snapshot.bubbles.count > 4 {
        Text("+\(entry.snapshot.bubbles.count - 4)")
          .font(.system(size: 11, weight: .medium, design: .monospaced))
          .foregroundStyle(WidgetSwarm.platinum.opacity(0.75))
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - StandBy systemMedium

  private var standByMediumBody: some View {
    ZStack {
      LinearGradient(
        colors: [WidgetSwarm.absoluteBlack, WidgetSwarm.field],
        startPoint: .top, endPoint: .bottom
      )
      .ignoresSafeArea()

      GeometryReader { geo in
        StandByWidgetOrbit(
          snapshot: entry.snapshot,
          size: geo.size,
          color: bubbleColor(for:),
          glow: bubbleGlow(for:)
        )
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
    return WidgetSwarm.platinum.opacity(0.35)
  }

  private func bubbleGlow(for b: WidgetSnapshot.Bubble) -> Color {
    bubbleColor(for: b).opacity(0.55)
  }
}

private struct CircularWidgetBubble: View {
  let color: Color
  let index: Int
  let total: Int

  private var angle: CGFloat {
    CGFloat(index) * (2 * .pi / CGFloat(max(total, 1))) - .pi / 2
  }

  var body: some View {
    Circle()
      .fill(color)
      .frame(width: 7, height: 7)
      .overlay(Circle().strokeBorder(WidgetSwarm.absoluteBlack.opacity(0.4), lineWidth: 0.4))
      .position(
        x: 28 + cos(angle) * 18,
        y: 28 + sin(angle) * 18
      )
  }
}

private struct RectangularWidgetBubble: View {
  let color: Color
  let handle: String

  var body: some View {
    Circle()
      .fill(color)
      .frame(width: 14, height: 14)
      .overlay(Circle().strokeBorder(WidgetSwarm.line, lineWidth: 0.5))
      .overlay(
        Text(String(handle.prefix(1)))
          .font(.system(size: 8, weight: .bold))
          .foregroundStyle(WidgetSwarm.absoluteBlack.opacity(0.78))
      )
  }
}

private struct StandByWidgetOrbit: View {
  let snapshot: WidgetSnapshot
  let size: CGSize
  let color: (WidgetSnapshot.Bubble) -> Color
  let glow: (WidgetSnapshot.Bubble) -> Color

  private var center: CGPoint {
    CGPoint(x: size.width / 2, y: size.height / 2)
  }

  private var radius: CGFloat {
    min(size.width, size.height) * 0.40
  }

  private var ringBubbles: [WidgetSnapshot.Bubble] {
    Array(snapshot.bubbles.prefix(8))
  }

  var body: some View {
    ZStack {
      Circle()
        .strokeBorder(WidgetSwarm.line, style: .init(lineWidth: 0.5, dash: [3, 3]))
        .frame(width: radius * 2, height: radius * 2)
        .position(center)

      Circle()
        .strokeBorder(WidgetSwarm.connected.opacity(0.75), lineWidth: 1)
        .background(Circle().fill(WidgetSwarm.surface))
        .frame(width: 26, height: 26)
        .shadow(color: WidgetSwarm.connected.opacity(0.20), radius: 8)
        .position(center)

      ForEach(Array(ringBubbles.enumerated()), id: \.offset) { index, bubble in
        StandByWidgetBubble(
          color: color(bubble),
          glow: glow(bubble),
          index: index,
          total: ringBubbles.count,
          center: center,
          radius: radius
        )
      }

      Text(String(format: "%02d live", snapshot.bubbles.count))
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(WidgetSwarm.platinum.opacity(0.55))
        .position(x: center.x, y: size.height - 14)
    }
  }
}

private struct StandByWidgetBubble: View {
  let color: Color
  let glow: Color
  let index: Int
  let total: Int
  let center: CGPoint
  let radius: CGFloat

  private var angle: CGFloat {
    CGFloat(index) * (2 * .pi / CGFloat(max(total, 1))) - .pi / 2
  }

  var body: some View {
    Circle()
      .fill(color)
      .frame(width: 16, height: 16)
      .overlay(Circle().strokeBorder(WidgetSwarm.line, lineWidth: 0.5))
      .shadow(color: glow, radius: 4)
      .position(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
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
