import SwiftUI

enum HaloTheme {
  // Background tokens (Deep Space, theme "nocturne")
  static let pureBlack         = Color.black
  static let background        = pureBlack
  static let surface           = Color(red: 20 / 255, green: 18 / 255, blue: 30 / 255).opacity(0.55)
  static let surfaceModal      = Color(red: 20 / 255, green: 18 / 255, blue: 30 / 255).opacity(0.72)
  static let portraitBacking   = Color(red: 26 / 255, green: 22 / 255, blue: 24 / 255)

  // Text
  static let text              = Color.white
  static let textSecondary     = Color.white.opacity(0.75)
  static let textMuted         = Color.white.opacity(0.5)
  static let textCaption       = Color.white.opacity(0.4)
  static let textHairline      = Color.white.opacity(0.35)

  // Strokes & rings
  static let hairline          = Color.white.opacity(0.12)
  static let hairlineSoft      = Color.white.opacity(0.08)
  static let ringInactive      = Color.white.opacity(0.07)
  static let ringActive        = Color.white.opacity(0.42)
  static let glassFallbackFill = Color.white.opacity(0.055)
  static let glassStroke       = Color.white.opacity(0.16)
  static let glassStrokeSoft   = Color.white.opacity(0.10)

  static let cornerRadius: CGFloat = 20
  static let sheetCornerRadius: CGFloat = 32

  // Mono digit font, used per timestamp e counter (ui-monospace nel design)
  static let mono = Font.system(.caption2, design: .monospaced)
}

extension View {
  /// Liquid Glass token per controlli e navigazione, con fallback material
  /// sulle versioni precedenti a iOS 26.
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

  /// Glass più quieto per card e contenuti: mantiene gerarchia senza trasformare
  /// tutto il contenuto in controlli fluttuanti.
  @ViewBuilder
  func haloContentGlass<S: InsettableShape>(
    in shape: S,
    stroke: Color = HaloTheme.glassStrokeSoft
  ) -> some View {
    self
      .background(Color.white.opacity(0.035), in: shape)
      .background(.regularMaterial, in: shape)
      .overlay(shape.strokeBorder(stroke, lineWidth: 0.5))
  }
}

extension Color {
  /// Parsing minimo di hex `#RRGGBB`. Su input invalido ritorna nero.
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
