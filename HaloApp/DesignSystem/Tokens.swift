import SwiftUI

/// Swarm Halo — single source of truth for all visual tokens.
///
/// See `docs/design-system/swarm-halo-v1.md`.
///
/// Token shape mirrors SWARM (`surface · ink · stroke · activation ·
/// radius · spacing · motion`) with Halo's warm-consumer customizations:
/// `warmBlack` instead of `absoluteBlack`, `paperCream` instead of
/// `platinum`, single `bronze` activation instead of SWARM's three.
///
/// The mood palette (`MoodPalette.swift`) is a parallel channel and
/// intentionally not part of this token set.
enum SwarmHalo {

  // MARK: - Surfaces

  static let absoluteBlack   = Color(hex: "#000000")
  static let warmBlack       = Color(hex: "#0F0E10")  // primary background
  static let nightSurface    = Color(hex: "#161516")  // card
  static let nightSurface2   = Color(hex: "#1B191A")  // modal sheet
  static let nightEdge       = Color(hex: "#07070A")  // separator

  // MARK: - Ink

  static let paperCream      = Color(hex: "#E4DDCF")
  static let creamLow        = paperCream.opacity(0.62)
  static let creamMute       = paperCream.opacity(0.42)
  static let creamHair       = paperCream.opacity(0.18)
  static let creamLine       = paperCream.opacity(0.10)
  static let creamWhisper    = paperCream.opacity(0.06)

  // MARK: - Activation (single bronze, vs SWARM's three)

  static let bronze          = Color(hex: "#A88260")
  static let bronzeSoft      = bronze.opacity(0.55)
  static let bronzeGlow      = bronze.opacity(0.35)

  // MARK: - Attention (errors, downgrades, reports — only)

  static let warmMagenta     = Color(hex: "#FF2B6E")

  // MARK: - Strokes

  static let strokeRest      = paperCream.opacity(0.12)
  static let strokeActive    = paperCream.opacity(0.42)
  static let strokeSoft      = paperCream.opacity(0.08)
  static let strokeHair      = paperCream.opacity(0.16)

  // MARK: - Radii (SWARM literal)

  static let radiusCard:  CGFloat = 6
  static let radiusInput: CGFloat = 4
  static let radiusChip:  CGFloat = 2
  static let radiusPill:  CGFloat = 999
  static let radiusSheet: CGFloat = 32   // sheet present, Halo extension

  // MARK: - Spacing (SWARM 4/8 scale)

  static let s1:  CGFloat = 4
  static let s2:  CGFloat = 8
  static let s3:  CGFloat = 12
  static let s4:  CGFloat = 16
  static let s6:  CGFloat = 24
  static let s8:  CGFloat = 32
  static let s12: CGFloat = 48
  static let s16: CGFloat = 64
  static let s24: CGFloat = 96
  static let s32: CGFloat = 128

  // MARK: - Motion durations

  static let durTap:        Double = 0.12
  static let durCardMount:  Double = 0.32
  static let durStagger:    Double = 0.04
  static let durSheet:      Double = 0.42
  static let durBreath:     Double = 4.0
  static let durLoader:     Double = 0.9
  static let durSelfBreath: Double = 6.0

  // MARK: - Motion easing

  /// SWARM signature easing — `cubic-bezier(0.2, 0.7, 0.1, 1)`.
  /// Use this for every transition that isn't a snap/tactical action.
  static let easeSwarm = Animation.timingCurve(0.2, 0.7, 0.1, 1)

  /// SWARM easing with explicit duration override.
  static func easeSwarm(_ duration: Double) -> Animation {
    .timingCurve(0.2, 0.7, 0.1, 1, duration: duration)
  }
}

// MARK: - Type families

/// PostScript names for the bundled fonts. Source: Google Fonts.
/// Registered in `HaloApp/Info.plist` under `UIAppFonts`.
enum SwarmHaloFont {

  enum Cormorant {
    static let regular       = "CormorantGaramond-Regular"
    static let italic        = "CormorantGaramond-Italic"
    static let medium        = "CormorantGaramond-Medium"
    static let mediumItalic  = "CormorantGaramond-MediumItalic"
  }

  enum Inter {
    static let regular   = "Inter-Regular"
    static let medium    = "Inter-Medium"
    static let semibold  = "Inter-SemiBold"
  }

  enum Plex {
    static let regular = "IBMPlexMono-Regular"
    static let medium  = "IBMPlexMono-Medium"
  }

  enum SpaceGrotesk {
    static let medium = "SpaceGrotesk-Medium"
  }
}
