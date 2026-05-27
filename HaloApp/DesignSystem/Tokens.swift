import SwiftUI
import HaloShared

/// SWARM Halo visual tokens used by app-side surfaces.
///
/// `absoluteBlack`, `platinum`, and activation values are confirmed by the
/// SWARM Fase A brief in `docs/design-system/swarm-v1.md`. The official
/// intermediate 14-step mono ramp is still an external brand asset, so the
/// semantic overlay tokens below avoid minting replacement hex steps.
enum SwarmHalo {

  // MARK: - Confirmed SWARM endpoints

  static let absoluteBlack = Color(hex: "#000000")
  static let platinum = Color(hex: "#E8E8EA")

  // MARK: - Activation

  /// Connected proximity state. SWARM token name is literal from brand.
  static let orbitalBlue = Color(hex: "#B8FF00")
  /// Operational proximity state. SWARM token name is literal from brand.
  static let signalGreen = Color(hex: "#7B2BFF")
  /// Attention state for alerts and widening warnings.
  static let launchAmber = Color(hex: "#FF2BB8")

  // MARK: - Semantic surfaces

  static let background = absoluteBlack
  static let surface = platinum.opacity(0.055)
  static let surfaceRaised = platinum.opacity(0.085)
  static let surfaceModal = platinum.opacity(0.11)
  static let edge = platinum.opacity(0.035)

  // MARK: - Semantic ink

  static let ink = platinum
  static let inkSecondary = platinum.opacity(0.68)
  static let inkMuted = platinum.opacity(0.44)
  static let inkHairline = platinum.opacity(0.18)
  static let inkLine = platinum.opacity(0.10)
  static let inkWhisper = platinum.opacity(0.06)

  // MARK: - Semantic strokes

  static let strokeRest = platinum.opacity(0.12)
  static let strokeActive = platinum.opacity(0.42)
  static let strokeSoft = platinum.opacity(0.08)
  static let strokeHair = platinum.opacity(0.16)

  // MARK: - Legacy aliases during migration

  static let warmBlack = background
  static let nightSurface = surface
  static let nightSurface2 = surfaceModal
  static let nightEdge = edge

  static let paperCream = ink
  static let creamLow = inkSecondary
  static let creamMute = inkMuted
  static let creamHair = inkHairline
  static let creamLine = inkLine
  static let creamWhisper = inkWhisper

  static let bronze = inkSecondary
  static let bronzeSoft = inkHairline
  static let bronzeGlow = inkLine
  static let warmMagenta = launchAmber

  // MARK: - Radii (SWARM literal)

  static let radiusCard:  CGFloat = 6
  static let radiusInput: CGFloat = 4
  static let radiusChip:  CGFloat = 2
  static let radiusPill:  CGFloat = 999
  static let radiusSheet: CGFloat = 24   // sheet present, Halo extension

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

// MARK: - Type scale

enum SwarmHaloTypeScale {
  static let hero: CGFloat = 144
  static let h1: CGFloat = 64
  static let h2: CGFloat = 40
  static let h3: CGFloat = 28
  static let lede: CGFloat = 17
  static let body: CGFloat = 15
  static let ui: CGFloat = 13
  static let eyebrow: CGFloat = 11
}

// MARK: - Halo tier mapping

/// App-side state mapping. `HaloShared` stays data-only and never imports
/// SwiftUI color types.
enum SwarmHaloTierState {
  case connected
  case operational
  case rest
  case farRest

  var accent: Color {
    switch self {
    case .connected: return SwarmHalo.orbitalBlue
    case .operational: return SwarmHalo.signalGreen
    case .rest: return SwarmHalo.platinum
    case .farRest: return SwarmHalo.absoluteBlack
    }
  }

  var stroke: Color {
    switch self {
    case .connected, .operational: return accent.opacity(0.26)
    case .rest: return SwarmHalo.strokeHair
    case .farRest: return SwarmHalo.absoluteBlack.opacity(0.84)
    }
  }

  var activeStroke: Color {
    switch self {
    case .rest: return SwarmHalo.platinum.opacity(0.44)
    case .farRest: return SwarmHalo.platinum.opacity(0.10)
    case .connected, .operational: return accent.opacity(0.64)
    }
  }

  var ringFill: Color {
    switch self {
    case .connected, .operational: return SwarmHalo.surfaceRaised
    case .rest: return SwarmHalo.platinum.opacity(0.16)
    case .farRest: return SwarmHalo.absoluteBlack
    }
  }

  var glow: Color {
    switch self {
    case .connected, .operational: return accent.opacity(0.05)
    case .rest: return SwarmHalo.platinum.opacity(0.08)
    case .farRest: return .clear
    }
  }

  var badgeFill: Color {
    switch self {
    case .connected, .operational: return accent.opacity(0.04)
    case .rest: return SwarmHalo.inkWhisper
    case .farRest: return SwarmHalo.absoluteBlack.opacity(0.72)
    }
  }
}

extension FriendshipTier {
  var swarmHaloState: SwarmHaloTierState {
    switch self {
    case .inner: return .connected
    case .close: return .operational
    case .orbit: return .rest
    case .nebula: return .farRest
    }
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

  /// Expected PostScript names for the licensed app bundle.
  enum Satoshi {
    static let regular = "Satoshi-Regular"
    static let medium = "Satoshi-Medium"
    static let bold = "Satoshi-Bold"
  }

  /// Bundled development fallback until Satoshi assets land.
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
