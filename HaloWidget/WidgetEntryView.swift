import SwiftUI
import WidgetKit
import HaloShared

/// Widget palette. Mirrors `HaloVisual.Palette` by hand — the widget target
/// can't import the app's design system — so keep the two in step.
///
/// Per `docs/DESIGN.md` R4 there is no brand accent here either: chrome is ink
/// on ground, and the only colour comes from a person's mood, via
/// `bubbleColor(for:)`. This matters more in the widget than anywhere else —
/// R5 makes the lockscreen the primary surface, so a row of coloured bubbles
/// on neutral chrome *is* the product.
private enum WidgetSwarm {
  /// True black — shadows only.
  static let absoluteBlack = Color.black
  /// The ground, matching `HaloVisual.Palette.ground` (#0B0C0E).
  static let field = Color(red: 11 / 255, green: 12 / 255, blue: 14 / 255)
  static let platinum = Color.white
  static let surface = platinum.opacity(0.08)
  static let line = platinum.opacity(0.16)
  static let hair = platinum.opacity(0.08)

  /// "You", and the ring around you. Neutral: presence, not a brand colour.
  /// Formerly SWARM lime `#B8FF00`.
  static let selfRing = platinum.opacity(0.55)
}

/// Render del widget Halo.
///
/// `docs/DESIGN.md` R5: *«zero testo oltre alle iniziali. Nessun conteggio,
/// nessun badge, nessuna notifica che chiede di essere aperta. Solo il colore
/// delle persone che cambia durante il giorno.»*
///
/// Ogni famiglia qui sotto mostrava invece un numero — il totale al centro del
/// circolare, l'overflow `+N` nel rettangolare, `NN live` nello StandBy. Un
/// conteggio è una metrica, e una metrica in schermata di blocco è una
/// richiesta di attenzione: esattamente il contrario del loop di presenza, dove
/// il widget deve lavorare anche quando l'utente non fa niente.
///
/// - `.accessoryCircular`: mini orbital field con 6 bolle radiali su un anello.
/// - `.accessoryRectangular`: bolle inline con le sole iniziali.
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
      Circle().strokeBorder(WidgetSwarm.selfRing, lineWidth: 0.8)
        .frame(width: 34, height: 34)
      ForEach(Array(circularBubbles.enumerated()), id: \.offset) { index, bubble in
        CircularWidgetBubble(
          color: bubbleColor(for: bubble),
          index: index,
          total: circularBubbles.count
        )
      }
    }
    .frame(width: 56, height: 56)
    .accessibilityLabel(presenceAccessibilityLabel)
  }

  // MARK: - Lockscreen rectangular

  /// Niente wordmark e niente `+N`: lo spazio guadagnato va in due bolle in
  /// più, che sono due persone in più invece di un numero.
  private var rectangularBody: some View {
    HStack(spacing: 6) {
      ForEach(entry.snapshot.bubbles.prefix(6), id: \.userId) { b in
        RectangularWidgetBubble(color: bubbleColor(for: b), handle: b.handle)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(presenceAccessibilityLabel)
  }

  // MARK: - StandBy systemMedium

  private var standByMediumBody: some View {
    ZStack {
      LinearGradient(
        colors: [WidgetSwarm.field, WidgetSwarm.absoluteBlack],
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

  // MARK: - accessibility

  /// R5 vieta il testo *visibile*, non l'accessibilità. VoiceOver non può
  /// leggere un colore, quindi la stessa informazione — chi c'è — passa da qui.
  private var presenceAccessibilityLabel: String {
    let count = entry.snapshot.bubbles.count
    switch count {
    case 0:  return "Nessuno adesso"
    case 1:  return "Una persona adesso"
    default: return "\(count) persone adesso"
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
        .strokeBorder(WidgetSwarm.selfRing.opacity(0.9), lineWidth: 1)
        .background(Circle().fill(WidgetSwarm.surface))
        .frame(width: 26, height: 26)
        .shadow(color: WidgetSwarm.absoluteBlack.opacity(0.35), radius: 8)
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
