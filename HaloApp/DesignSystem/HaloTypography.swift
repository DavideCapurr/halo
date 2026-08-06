import SwiftUI

/// Halo type system — **one family**, per `docs/DESIGN.md` R3.
///
/// Hierarchy is carried by size, weight and opacity. Never by typeface.
///
/// The four brand families are gone. Editorial Cormorant italic on people's
/// names was beautiful and wrong: it turned friends into a magazine masthead —
/// content to look at, rather than people to answer. Every role below now
/// resolves to the system face, which also removes the licensed-Satoshi
/// dependency that blocked the type system, the ~2 MB font bundle, and the
/// risk of a silent fallback when a PostScript name doesn't resolve.
///
/// The role functions are kept so call sites don't change. `serif()` and
/// `eyebrow()` are now names for *sizes and weights*, not for faces.
enum HaloType {

  /// Official global readability multiplier — the single knob for the whole
  /// Halo type system. Every `HaloType.*` size is multiplied by this at render
  /// time, so the base px values in `SwarmHaloTypeScale` and the design-system
  /// docs render at `px × scale` (e.g. hero 72 → ~83pt). Change here, not in
  /// call sites.
  static let scale: CGFloat = 1.15

  private static func scaled(_ size: CGFloat) -> CGFloat { size * scale }

  // MARK: - display roles (were serif — now weight, not face)

  /// Display role. Formerly editorial italic serif; now the system face at a
  /// lighter weight, which is what gives large type its calm at size.
  static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: scaled(size), weight: displayWeight(weight))
  }

  /// Kept for call-site compatibility — identical to `serif` now that there is
  /// no second face to be upright in.
  static func serifUpright(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    serif(size, weight: weight)
  }

  // MARK: - body & controls

  static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: scaled(size), weight: weight)
  }

  static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
    .system(size: scaled(size), weight: weight)
  }

  // MARK: - numerals

  /// Timestamps, counts, countdowns. Same family — only the digits are made
  /// monospaced, so columns line up without introducing a second typeface.
  static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
    .system(size: scaled(size), weight: weight).monospacedDigit()
  }

  // MARK: - eyebrow

  /// Use with `.kerning(2.4-2.6)`, `.textCase(.uppercase)`. The
  /// `haloEyebrow` modifier already applies those.
  static func eyebrow(_ size: CGFloat) -> Font {
    .system(size: scaled(size), weight: .medium)
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
    serif(SwarmHaloTypeScale.h1, weight: .regular)
  }

  static func h2() -> Font {
    serif(SwarmHaloTypeScale.h2, weight: .regular)
  }

  static func h3() -> Font {
    serif(SwarmHaloTypeScale.h3, weight: .regular)
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

  /// Large type wants *less* weight, not more: at hero and h1 sizes a regular
  /// weight reads heavy. Display roles cap at `.light` unless a caller has
  /// explicitly asked for emphasis.
  private static func displayWeight(_ requested: Font.Weight) -> Font.Weight {
    switch requested {
    case .bold, .semibold, .medium: return .medium
    default:                        return .light
    }
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

  // Deprecated — neutral since `docs/DESIGN.md` R4 removed the brand accent.
  // For a person, use a mood colour (`MoodPalette`); for chrome, plain ink.
  static let bronze        = SwarmHalo.bronze
  static let bronzeSoft    = SwarmHalo.bronzeSoft
  static let bronzeGlow    = SwarmHalo.bronzeGlow

  static let nightSurface  = SwarmHalo.surface
  static let nightSurface2 = SwarmHalo.surfaceModal
  static let nightEdge     = SwarmHalo.edge

  /// Attention state — errors, downgrades, reports only. Warm magenta #FF2B6E.
  static let warmMagenta   = SwarmHalo.attention

  /// Text/overlay drawn on top of media (photos).
  static let onMedia       = SwarmHalo.cream
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
