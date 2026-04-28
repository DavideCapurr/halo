import SwiftUI

/// Halo v2 type system: editorial / Saint-Laurent / late-night nonchalant.
///
/// Three voices:
///  - **serif** (italic display) — for names, vibe quotes, big headlines.
///  - **ui** (rounded grotesk) — for body, controls, navigation labels.
///  - **mono** (monospaced) — for timestamps, counts, small-cap labels.
///
/// We keep system fonts so there's nothing to bundle; the *design* (italic
/// serif + tight tracking + small caps) is what carries the editorial feel.
enum HaloType {

  // MARK: - serif (display / italic, used for names + quotes)

  /// Italic serif at the given size. Falls back to the system "new york"
  /// face which carries the editorial italics close to *Instrument Serif*.
  static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .serif).italic()
  }

  /// Non-italic serif (rare — used for crests/numerals).
  static func serifUpright(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .serif)
  }

  // MARK: - ui (rounded grotesk, replaces Geist)

  /// UI grotesk. Rounded keeps it friendly without becoming playful.
  static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .rounded)
  }

  // MARK: - mono (timestamps, small-cap labels)

  /// Monospaced. Use for timestamps, counts, "n° 01" style markers.
  static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
    .system(size: size, weight: weight, design: .monospaced)
  }
}

/// Halo v2 colour ink: cream/bronze on warm-black, layered with glass.
enum HaloInk {
  /// Soft paper cream. Primary text on dark surfaces.
  static let cream         = Color(red: 0.894, green: 0.867, blue: 0.812)
  static let creamLow      = Color(red: 0.894, green: 0.867, blue: 0.812).opacity(0.62)
  static let creamMute     = Color(red: 0.894, green: 0.867, blue: 0.812).opacity(0.42)
  static let creamHair     = Color(red: 0.894, green: 0.867, blue: 0.812).opacity(0.18)
  static let creamLine     = Color(red: 0.894, green: 0.867, blue: 0.812).opacity(0.10)
  static let creamWhisper  = Color(red: 0.894, green: 0.867, blue: 0.812).opacity(0.06)

  /// Warm bronze accent — single-use per surface (active state, key signal).
  static let bronze        = Color(red: 0.659, green: 0.510, blue: 0.353)
  static let bronzeSoft    = Color(red: 0.659, green: 0.510, blue: 0.353).opacity(0.55)
  static let bronzeGlow    = Color(red: 0.659, green: 0.510, blue: 0.353).opacity(0.35)

  /// Warm-tinted near-black — anchor for sheets and tab-bar fills.
  static let nightSurface  = Color(red: 0.060, green: 0.058, blue: 0.060)
  static let nightSurface2 = Color(red: 0.085, green: 0.080, blue: 0.080)
  static let nightEdge     = Color(red: 0.027, green: 0.027, blue: 0.030)
}

extension View {
  /// Editorial small-caps tab/section header style — uppercase, tight track,
  /// JetBrains-Mono-ish vibe. Applies font, kerning, casing, and color.
  func haloEyebrow(
    _ color: Color = HaloInk.creamMute,
    size: CGFloat = 9.5,
    tracking: CGFloat = 2.6
  ) -> some View {
    self
      .font(HaloType.mono(size, weight: .medium))
      .kerning(tracking)
      .textCase(.uppercase)
      .foregroundStyle(color)
  }
}
