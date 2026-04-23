import SwiftUI

enum HaloTheme {
  static let background = Color.black
  static let surface    = Color(white: 0.08)
  static let text       = Color.white
  static let textMuted  = Color(white: 0.6)
  static let ringStroke = Color.white.opacity(0.15)

  static let cornerRadius: CGFloat = 20
  static let ringCount: Int = 4   // inner, close, orbit, nebula
}

extension Color {
  /// Parsing minimo per hex "#RRGGBB". Ritorna nero su input invalido.
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
