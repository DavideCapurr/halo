import SwiftUI
import UIKit

/// SWARM Halo type system.
///
/// Four brand families:
///  - **serif** (Cormorant Garamond italic) — names, vibe quotes, manifesto
///  - **serifUpright** (Cormorant Garamond regular) — rare, crests/numerals
///  - **display/ui** (Satoshi) — body, controls, navigation labels
///  - **mono** (IBM Plex Mono) — timestamps, counts, telemetry strips
///  - **eyebrow** (Space Grotesk) — small-cap section headers
///
/// Satoshi is an external licensed Fase A dependency. Inter remains a bundled
/// development fallback until the official Satoshi files are registered.
enum HaloType {

  /// Scala globale di leggibilità. Unico punto per ingrandire tutta la tipografia Halo.
  static let scale: CGFloat = 1.15

  private static func scaled(_ size: CGFloat) -> CGFloat { size * scale }

  // MARK: - serif (Cormorant Garamond italic — display)

  /// Editorial italic serif. The brand voice — used for names, manifesto,
  /// vibe notes.
  static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(serifName(weight: weight, italic: true),
            size: scaled(size),
            relativeTo: .title)
  }

  /// Non-italic serif (rare — used for crests, ordinal markers).
  static func serifUpright(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(serifName(weight: weight, italic: false),
            size: scaled(size),
            relativeTo: .title)
  }

  // MARK: - display/ui (Satoshi — body & controls)

  static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(uiName(weight: weight),
            size: scaled(size),
            relativeTo: .body)
  }

  static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
    .custom(uiName(weight: weight),
            size: scaled(size),
            relativeTo: .title)
  }

  // MARK: - mono (IBM Plex Mono — telemetry)

  static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
    .custom(monoName(weight: weight),
            size: scaled(size),
            relativeTo: .caption)
  }

  // MARK: - eyebrow (Space Grotesk — small-cap section headers)

  /// Use with `.kerning(2.4-2.6)`, `.textCase(.uppercase)`. The
  /// `haloEyebrow` modifier already applies those.
  static func eyebrow(_ size: CGFloat) -> Font {
    .custom(SwarmHaloFont.SpaceGrotesk.medium,
            size: scaled(size),
            relativeTo: .caption2)
  }

  // MARK: - system (SF Symbols & fallback — shares the global scale)

  static func system(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: scaled(size), weight: weight)
  }

  // MARK: - SWARM roles

  static func hero() -> Font {
    serif(SwarmHaloTypeScale.hero, weight: .regular)
  }

  static func h1() -> Font {
    display(SwarmHaloTypeScale.h1, weight: .medium)
  }

  static func h2() -> Font {
    display(SwarmHaloTypeScale.h2, weight: .medium)
  }

  static func h3() -> Font {
    display(SwarmHaloTypeScale.h3, weight: .medium)
  }

  static func lede() -> Font {
    ui(SwarmHaloTypeScale.lede, weight: .regular)
  }

  static func body() -> Font {
    ui(SwarmHaloTypeScale.body, weight: .regular)
  }

  static func uiRole() -> Font {
    ui(SwarmHaloTypeScale.ui, weight: .medium)
  }

  static func eyebrowRole() -> Font {
    eyebrow(SwarmHaloTypeScale.eyebrow)
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
    case .bold, .semibold:
      return availableFont(SwarmHaloFont.Satoshi.bold, fallback: SwarmHaloFont.Inter.semibold)
    case .medium:
      return availableFont(SwarmHaloFont.Satoshi.medium, fallback: SwarmHaloFont.Inter.medium)
    default:
      return availableFont(SwarmHaloFont.Satoshi.regular, fallback: SwarmHaloFont.Inter.regular)
    }
  }

  private static func monoName(weight: Font.Weight) -> String {
    switch weight {
    case .medium, .semibold, .bold: return SwarmHaloFont.Plex.medium
    default:                          return SwarmHaloFont.Plex.regular
    }
  }

  private static func availableFont(_ preferred: String, fallback: String) -> String {
    UIFont(name: preferred, size: 12) == nil ? fallback : preferred
  }
}

/// Halo ink — semantic color tokens, backwards-compatible facade.
/// All values now resolve to `SwarmHalo.*`. See `Tokens.swift`.
enum HaloInk {
  static let cream         = SwarmHalo.ink
  static let creamLow      = SwarmHalo.inkSecondary
  static let creamMute     = SwarmHalo.inkMuted
  static let creamHair     = SwarmHalo.inkHairline
  static let creamLine     = SwarmHalo.inkLine
  static let creamWhisper  = SwarmHalo.inkWhisper

  static let bronze        = SwarmHalo.inkSecondary
  static let bronzeSoft    = SwarmHalo.inkHairline
  static let bronzeGlow    = SwarmHalo.inkLine

  static let nightSurface  = SwarmHalo.surface
  static let nightSurface2 = SwarmHalo.surfaceModal
  static let nightEdge     = SwarmHalo.edge

  /// Attention state — errors, downgrades, reports only. Sparingly.
  static let warmMagenta   = SwarmHalo.launchAmber
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
