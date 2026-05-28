import SwiftUI
import HaloShared

/// Token colore per il design Halo Orbital Field.
/// Equivalente Swift di `auraColor(mood, l)` e `auraRing(mood, alpha)` del prototipo JS,
/// con conversione OKLCH → sRGB on the fly.
enum MoodPalette {
  /// Colore "aura" pieno per un mood, alla luminanza data (default 0.58 come nel design).
  static func auraColor(_ mood: Mood, l: Double = 0.58) -> Color {
    HaloVisual.Aura.color(mood, luminance: l)
  }

  /// Variante semitrasparente con luminanza fissa 0.55, usata per glow/halo.
  static func auraRing(_ mood: Mood, alpha: Double = 0.35) -> Color {
    HaloVisual.Aura.color(mood, luminance: 0.55, alpha: alpha)
  }
}

extension Color {
  /// OKLCH → sRGB. h in gradi, c chroma, l luminanza percepita [0…1].
  static func fromOKLCH(l: Double, c: Double, h: Double, alpha: Double = 1.0) -> Color {
    let hRad = h * .pi / 180
    // OKLCH → OKLab
    let a = c * cos(hRad)
    let bLab = c * sin(hRad)
    // OKLab → linear sRGB (matrice da Björn Ottosson, "A perceptual color space for image processing")
    let l_ = l + 0.3963377774 * a + 0.2158037573 * bLab
    let m_ = l - 0.1055613458 * a - 0.0638541728 * bLab
    let s_ = l - 0.0894841775 * a - 1.2914855480 * bLab

    let lc = l_ * l_ * l_
    let mc = m_ * m_ * m_
    let sc = s_ * s_ * s_

    let rLin =  4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc
    let gLin = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc
    let bLin = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc

    return Color(
      .sRGB,
      red:   Self.linearToSRGB(rLin).clamped(),
      green: Self.linearToSRGB(gLin).clamped(),
      blue:  Self.linearToSRGB(bLin).clamped(),
      opacity: alpha
    )
  }

  private static func linearToSRGB(_ v: Double) -> Double {
    if v <= 0 { return 0 }
    if v >= 1 { return 1 }
    return v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1 / 2.4) - 0.055
  }
}

private extension Double {
  func clamped(_ lo: Double = 0, _ hi: Double = 1) -> Double {
    Swift.max(lo, Swift.min(hi, self))
  }
}
