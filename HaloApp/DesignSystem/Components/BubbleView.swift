import SwiftUI
import HaloShared

/// Bolla editoriale v2: monogram tile monocromatico, mood ridotto a micro-dot,
/// underline bronzo per "adesso". Niente aura rainbow: la forma diventa brand.
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

  private var monogram: String {
    let source = handle.isEmpty ? personId : handle
    return String(source.prefix(1)).uppercased()
  }

  private var tile: MonogramTileSpec {
    MonogramTileSpec(id: personId)
  }

  var body: some View {
    ZStack {
      MonogramTile(letter: monogram, spec: tile, size: size, ringTone: hasActiveVibe ? .inner : .hair)

      Circle()
        .fill(MoodPalette.auraColor(mood, l: hasActiveVibe ? 0.74 : 0.46))
        .frame(width: max(5, size * 0.12), height: max(5, size * 0.12))
        .overlay(Circle().stroke(HaloInk.nightSurface, lineWidth: 1))
        .opacity(hasActiveVibe ? 0.95 : 0.45)
        .offset(x: size * 0.43, y: -size * 0.43)

      if isAdesso {
        Capsule()
          .fill(HaloInk.bronze)
          .frame(width: size * 0.44, height: 1.2)
          .shadow(color: HaloInk.bronzeGlow, radius: 4)
          .offset(y: size * 0.52 + 4)
      }

      if showName {
        Text(handle)
          .font(HaloType.serif(max(11, size * 0.17)))
          .foregroundStyle(HaloInk.creamLow)
          .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
          .lineLimit(1)
          .fixedSize()
          .offset(y: size * 0.5 + 14)
      }
    }
    .frame(width: size, height: size)
  }
}

struct MonogramTile: View {
  enum RingTone {
    case hair
    case inner
    case hero
  }

  let letter: String
  let spec: MonogramTileSpec
  let size: CGFloat
  var ringTone: RingTone = .hair

  private var ringColor: Color {
    switch ringTone {
    case .hair: return HaloInk.creamHair
    case .inner: return HaloInk.cream.opacity(0.32)
    case .hero: return HaloInk.bronze.opacity(0.82)
    }
  }

  private var ringWidth: CGFloat {
    ringTone == .hero ? 1.4 : 0.8
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
        .fill(spec.background)
        .overlay(
          RadialGradient(
            colors: [Color.white.opacity(0.06), .clear],
            center: spec.hotspot,
            startRadius: 0,
            endRadius: size * 0.68
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
            .strokeBorder(ringColor, lineWidth: ringWidth)
        )
        .shadow(color: .black.opacity(0.46), radius: size * 0.18, y: size * 0.08)

      Text(letter)
        .font(HaloType.serif(size * 0.54))
        .foregroundStyle(spec.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .offset(y: size * 0.02)
        .rotationEffect(.degrees(spec.rotation))
        .shadow(color: .black.opacity(0.45), radius: 0, y: 1)
    }
    .frame(width: size, height: size)
  }
}

struct MonogramTileSpec {
  let background: Color
  let ink: Color
  let hotspot: UnitPoint
  let rotation: Double

  init(id: String) {
    let h = Self.hash(id + "|tile")
    let backgrounds = [
      Color(red: 0.096, green: 0.086, blue: 0.078),
      Color(red: 0.122, green: 0.110, blue: 0.096),
      Color(red: 0.074, green: 0.078, blue: 0.084),
      Color(red: 0.128, green: 0.102, blue: 0.088),
      Color(red: 0.086, green: 0.082, blue: 0.078),
      Color(red: 0.112, green: 0.100, blue: 0.104),
    ]
    let inks = [
      HaloInk.cream.opacity(0.88),
      HaloInk.creamLow,
      Color(red: 0.72, green: 0.66, blue: 0.56),
      Color(red: 0.62, green: 0.58, blue: 0.52),
    ]
    background = backgrounds[Int(h % UInt32(backgrounds.count))]
    ink = inks[Int((h >> 5) % UInt32(inks.count))]
    hotspot = UnitPoint(
      x: 0.26 + CGFloat((h >> 8) % 50) / 100.0,
      y: 0.18 + CGFloat((h >> 13) % 48) / 100.0
    )
    rotation = Double(Int((h >> 19) % 7)) - 3.0
  }

  private static func hash(_ string: String, seed: UInt32 = 2166136261) -> UInt32 {
    var h = seed
    for u in string.unicodeScalars {
      h = (h ^ u.value) &* 16777619
    }
    return h
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
