import SwiftUI
import HaloShared

/// Backwards-compatible visual tokens used by app-side surfaces.
///
/// Keep the concrete visual direction in `HaloVisual` below. The older
/// `SwarmHalo`/`HaloTheme` facade remains so existing screens inherit palette
/// changes without a global refactor.
enum SwarmHalo {

  // MARK: - Current endpoints

  static let absoluteBlack = HaloVisual.Palette.absoluteBlack
  static let platinum = HaloVisual.Palette.cream

  // MARK: - Activation

  /// Connected proximity state.
  static let orbitalBlue = HaloVisual.Aura.color(.electric)
  /// Operational proximity state.
  static let signalGreen = HaloVisual.Aura.color(.focused)
  /// Attention state for alerts and widening warnings.
  static let launchAmber = HaloVisual.Aura.color(.wild)

  // MARK: - Semantic surfaces

  static let background = HaloVisual.Palette.warmBlack
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

  static let warmBlack = HaloVisual.Palette.warmBlack
  static let nightSurface = HaloVisual.Palette.nightSurface
  static let nightSurface2 = HaloVisual.Palette.nightSurface2
  static let nightEdge = HaloVisual.Palette.creamWhisper

  static let paperCream = HaloVisual.Palette.cream
  static let creamLow = HaloVisual.Palette.creamLow
  static let creamMute = HaloVisual.Palette.creamMute
  static let creamHair = HaloVisual.Palette.creamHair
  static let creamLine = HaloVisual.Palette.creamLine
  static let creamWhisper = HaloVisual.Palette.creamWhisper

  static let bronze = HaloVisual.Palette.bronze
  static let bronzeSoft = HaloVisual.Palette.bronzeSoft
  static let bronzeGlow = HaloVisual.Palette.bronzeGlow
  static let warmMagenta = HaloVisual.Aura.color(.soft)

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
    case .asteroid: return .farRest
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

// MARK: - App-wide editable visual direction

/// Single edit point for the current Halo visual direction.
///
/// Keep surface-specific views wired to these values instead of hardcoding
/// hex colors, mood hues, radii, or key sizing constants in feature files.
enum HaloVisual {
  enum Palette {
    static let absoluteBlack = Color(hex: "#000000")
    static let warmBlack = Color(hex: "#0F0E10")
    static let nightSurface = Color(hex: "#161516")
    static let nightSurface2 = Color(hex: "#1B191A")

    static let cream = Color(hex: "#E4DDCF")
    static let creamLow = cream.opacity(0.62)
    static let creamMute = cream.opacity(0.42)
    static let creamHair = cream.opacity(0.18)
    static let creamLine = cream.opacity(0.10)
    static let creamWhisper = cream.opacity(0.06)

    static let bronze = Color(hex: "#A88260")
    static let bronzeSoft = bronze.opacity(0.55)
    static let bronzeGlow = bronze.opacity(0.35)

    static let glassInkFill = Color(red: 11 / 255, green: 14 / 255, blue: 17 / 255)
  }

  enum Aura {
    static func color(_ mood: Mood, alpha: Double = 1) -> Color {
      color(mood, luminance: nil, alpha: alpha)
    }

    static func color(_ mood: Mood, luminance: Double?, alpha: Double = 1) -> Color {
      let token = token(for: mood)
      return Color.fromOKLCH(l: luminance ?? token.l, c: token.c, h: token.h, alpha: alpha)
    }

    private static func token(for mood: Mood) -> (l: Double, c: Double, h: Double) {
      switch mood {
      case .chill:
        return (0.78, 0.10, 220)
      case .wild:
        return (0.74, 0.18, 30)
      case .focused:
        return (0.78, 0.12, 160)
      case .warm:
        return (0.80, 0.14, 60)
      case .electric:
        return (0.86, 0.18, 145)
      case .blue:
        return (0.66, 0.16, 250)
      case .soft:
        return (0.82, 0.10, 350)
      case .lost:
        return (0.62, 0.07, 290)
      }
    }
  }

  enum Typography {
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
      let name: String
      switch weight {
      case .bold, .semibold:
        name = SwarmHaloFont.Inter.semibold
      case .medium:
        name = SwarmHaloFont.Inter.medium
      default:
        name = SwarmHaloFont.Inter.regular
      }

      return .custom(name, size: size, relativeTo: .body)
    }
  }

  enum Orbita {
    static let contentTopPadding: CGFloat = 48
    static let sectionGap: CGFloat = 12

    static let headerHorizontalPadding: CGFloat = 26
    static let headerTopPadding: CGFloat = 14
    static let headerBottomPadding: CGFloat = 4
    static let logoRingSize: CGFloat = 9
    static let logoRingLeading: CGFloat = 18
    static let logoTextSize: CGFloat = 15
    static let logoTracking: CGFloat = 6.3
    static let logoTextLeading: CGFloat = 6.3
    static let vibePillTopPadding: CGFloat = 12
    static let vibePillHorizontalPadding: CGFloat = 11
    static let vibePillVerticalPadding: CGFloat = 6
    static let vibeDotSize: CGFloat = 7
    static let headerPillFillOpacity = 0.55

    static let heroHorizontalPadding: CGFloat = 22
    static let heroTopPadding: CGFloat = 14
    static let heroCardRadius: CGFloat = 14
    static let heroCardHorizontalPadding: CGFloat = 12
    static let heroCardVerticalPadding: CGFloat = 10
    static let heroPortraitSize: CGFloat = 44
    static let heroPortraitFontSize: CGFloat = 22
    static let heroDotSize: CGFloat = 8

    static let fieldBaseWidth: CGFloat = 360
    static let fieldBaseHeight: CGFloat = 533
    static let fieldMinScale: CGFloat = 0.86
    static let innerRadius: CGFloat = 78
    static let closeRadius: CGFloat = 130
    static let orbitRadius: CGFloat = 172
    static let innerBubbleSize: CGFloat = 36
    static let closeBubbleSize: CGFloat = 26
    static let orbitBubbleSize: CGFloat = 18

    static let selfOuterSize: CGFloat = 64
    static let selfInnerSize: CGFloat = 48
    static let selfFrameSize: CGFloat = 118

    static let zoomRailTrailingPadding: CGFloat = 10
    static let zoomRailFillOpacity = 0.45
    static let zoomRailLineHeight: CGFloat = 64

    static let footerBottomPadding: CGFloat = 92
    static let footerSafeAreaExtra: CGFloat = 70
  }
}
