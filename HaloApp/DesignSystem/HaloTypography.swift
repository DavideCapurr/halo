import SwiftUI

/// Halo type system, swarm-halo v1.
///
/// Four families, mirror of the SWARM brand-book:
///  - **serif** (Cormorant Garamond italic) — names, vibe quotes, manifesto
///  - **serifUpright** (Cormorant Garamond regular) — rare, crests/numerals
///  - **ui** (Inter) — body, controls, navigation labels
///  - **mono** (IBM Plex Mono) — timestamps, counts, telemetry strips
///  - **eyebrow** (Space Grotesk) — small-cap section headers
///
/// All four are bundled in `HaloApp/Resources/Fonts/` and registered in
/// `Info.plist` under `UIAppFonts`. `.custom` falls back to system fonts
/// silently if the file isn't loaded, so dev mode without the bundle
/// still renders sensibly.
enum HaloType {

  // MARK: - serif (Cormorant Garamond italic — display)

  /// Editorial italic serif. The brand voice — used for names, manifesto,
  /// vibe notes.
  static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(serifName(weight: weight, italic: true),
            size: size,
            relativeTo: .title)
  }

  /// Non-italic serif (rare — used for crests, ordinal markers).
  static func serifUpright(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(serifName(weight: weight, italic: false),
            size: size,
            relativeTo: .title)
  }

  // MARK: - ui (Inter — body & controls)

  static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(uiName(weight: weight),
            size: size,
            relativeTo: .body)
  }

  // MARK: - mono (IBM Plex Mono — telemetry)

  static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
    .custom(monoName(weight: weight),
            size: size,
            relativeTo: .caption)
  }

  // MARK: - eyebrow (Space Grotesk — small-cap section headers)

  /// Use with `.kerning(2.4-2.6)`, `.textCase(.uppercase)`. The
  /// `haloEyebrow` modifier already applies those.
  static func eyebrow(_ size: CGFloat) -> Font {
    .custom(SwarmHaloFont.SpaceGrotesk.medium,
            size: size,
            relativeTo: .caption2)
  }

  // MARK: - private resolution

  private static func serifName(weight: Font.Weight, italic: Bool) -> String {
    let isMedium = (weight == .medium || weight == .semibold || weight == .bold)
    switch (italic, isMedium) {
    case (true, true):   return SwarmHaloFont.Cormorant.mediumItalic
    case (true, false):  return SwarmHaloFont.Cormorant.italic
    case (false, true):  return SwarmHaloFont.Cormorant.medium
    case (false, false): return SwarmHaloFont.Cormorant.regular
    }
  }

  private static func uiName(weight: Font.Weight) -> String {
    switch weight {
    case .bold, .semibold: return SwarmHaloFont.Inter.semibold
    case .medium:          return SwarmHaloFont.Inter.medium
    default:                return SwarmHaloFont.Inter.regular
    }
  }

  private static func monoName(weight: Font.Weight) -> String {
    switch weight {
    case .medium, .semibold, .bold: return SwarmHaloFont.Plex.medium
    default:                          return SwarmHaloFont.Plex.regular
    }
  }
}

/// Halo ink — semantic color tokens, backwards-compatible facade.
/// All values now resolve to `SwarmHalo.*`. See `Tokens.swift`.
enum HaloInk {
  static let cream         = SwarmHalo.paperCream
  static let creamLow      = SwarmHalo.creamLow
  static let creamMute     = SwarmHalo.creamMute
  static let creamHair     = SwarmHalo.creamHair
  static let creamLine     = SwarmHalo.creamLine
  static let creamWhisper  = SwarmHalo.creamWhisper

  static let bronze        = SwarmHalo.bronze
  static let bronzeSoft    = SwarmHalo.bronzeSoft
  static let bronzeGlow    = SwarmHalo.bronzeGlow

  static let nightSurface  = SwarmHalo.nightSurface
  static let nightSurface2 = SwarmHalo.nightSurface2
  static let nightEdge     = SwarmHalo.nightEdge

  /// Attention state — errors, downgrades, reports only. Sparingly.
  static let warmMagenta   = SwarmHalo.warmMagenta
}

extension View {
  /// Editorial small-cap eyebrow style — uppercase, tight tracking, Space
  /// Grotesk. Applies font, kerning, casing, and color.
  func haloEyebrow(
    _ color: Color = HaloInk.creamMute,
    size: CGFloat = 9.5,
    tracking: CGFloat = 2.6
  ) -> some View {
    self
      .font(HaloType.eyebrow(size))
      .kerning(tracking)
      .textCase(.uppercase)
      .foregroundStyle(color)
  }
}
