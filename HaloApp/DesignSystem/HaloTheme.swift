import SwiftUI

/// Halo theme — thin backwards-compatible facade over `SwarmHalo`.
///
/// All concrete values live in `Tokens.swift`. This file exists so that
/// the dozens of components that already reference `HaloTheme.*` keep
/// working without a global refactor.
enum HaloTheme {
  // Background tokens
  static let pureBlack         = SwarmHalo.absoluteBlack
  static let background        = SwarmHalo.warmBlack
  static let surface           = SwarmHalo.nightSurface
  static let surfaceModal      = SwarmHalo.nightSurface2
  static let portraitBacking   = Color(red: 26 / 255, green: 22 / 255, blue: 24 / 255)

  // Text
  static let text              = SwarmHalo.paperCream
  static let textSecondary     = SwarmHalo.creamLow
  static let textMuted         = SwarmHalo.creamMute
  static let textCaption       = SwarmHalo.creamMute
  static let textHairline      = SwarmHalo.creamHair

  // Strokes & rings
  static let hairline          = SwarmHalo.strokeRest
  static let hairlineSoft      = SwarmHalo.strokeSoft
  static let ringInactive      = SwarmHalo.paperCream.opacity(0.07)
  static let ringActive        = SwarmHalo.strokeActive
  static let glassFallbackFill = SwarmHalo.paperCream.opacity(0.055)
  static let glassStroke       = SwarmHalo.strokeHair
  static let glassStrokeSoft   = SwarmHalo.paperCream.opacity(0.10)

  static let cornerRadius: CGFloat = 20
  static let sheetCornerRadius: CGFloat = SwarmHalo.radiusSheet

  /// Mono digit font for timestamps and counters. Now uses IBM Plex Mono.
  static let mono = Font.custom(SwarmHaloFont.Plex.medium, size: 11, relativeTo: .caption2)
}

extension View {
  /// Liquid Glass token for controls and navigation, with material fallback
  /// on versions earlier than iOS 26.
  @ViewBuilder
  func haloGlass<S: InsettableShape>(
    in shape: S,
    tint: Color? = nil,
    interactive: Bool = false,
    stroke: Color = HaloTheme.glassStroke
  ) -> some View {
    if #available(iOS 26.0, *) {
      self.glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
    } else {
      self
        .background(HaloTheme.glassFallbackFill, in: shape)
        .background(.ultraThinMaterial, in: shape)
        .overlay(shape.strokeBorder(stroke, lineWidth: 0.6))
    }
  }

  /// Quieter glass for cards and content surfaces.
  @ViewBuilder
  func haloContentGlass<S: InsettableShape>(
    in shape: S,
    stroke: Color = HaloTheme.glassStrokeSoft
  ) -> some View {
    self
      .background(SwarmHalo.creamWhisper, in: shape)
      .background(.regularMaterial, in: shape)
      .overlay(shape.strokeBorder(stroke, lineWidth: 0.5))
  }
}

extension Color {
  /// Minimal `#RRGGBB` hex parser. Returns black on invalid input.
  init(hex: String) {
    var h = hex
    if h.hasPrefix("#") { h.removeFirst() }
    guard h.count == 6, let v = UInt32(h, radix: 16) else {
      self = .black
      return
    }
    let r = Double((v >> 16) & 0xFF) / 255.0
    let g = Double((v >>  8) & 0xFF) / 255.0
    let b = Double( v        & 0xFF) / 255.0
    self = Color(red: r, green: g, blue: b)
  }
}
