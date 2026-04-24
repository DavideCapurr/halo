import SwiftUI
import UIKit

/// Portrait generativo (skin + hair + shirt + tratti) basato su hash deterministico
/// dell'id persona. Equivalente Swift di `PortraitSVG` del prototipo design.
/// Reso in un coordinate space di 100×100 con `.scaleEffect(size/100)`.
struct PortraitView: View {
  let personId: String
  var size: CGFloat = 80
  var grayscale: Bool = false

  private static let skinTones: [Color] = [
    Color(hex: "#f4d1b0"), Color(hex: "#e5b594"), Color(hex: "#cf9773"),
    Color(hex: "#b07a55"), Color(hex: "#8a5a3a"), Color(hex: "#6b4226"),
    Color(hex: "#ecc5a2"), Color(hex: "#d9a37d"), Color(hex: "#a87250"),
  ]
  private static let hairColors: [Color] = [
    Color(hex: "#1a1208"), Color(hex: "#2d1d10"), Color(hex: "#4a2f1a"),
    Color(hex: "#6b4422"), Color(hex: "#8a5a2e"), Color(hex: "#c8984a"),
    Color(hex: "#d8b878"), Color(hex: "#e8c98a"), Color(hex: "#3d2416"),
    Color(hex: "#141010"), Color(hex: "#6a4a3a"), Color(hex: "#8c6647"),
  ]
  private static let shirtColors: [Color] = [
    Color(hex: "#2a2d3a"), Color(hex: "#33262d"), Color(hex: "#1f2a33"),
    Color(hex: "#2d2a1e"), Color(hex: "#262a2a"), Color(hex: "#3a2a33"),
    Color(hex: "#1e2d2a"), Color(hex: "#2a1e26"), Color(hex: "#1a1e2a"),
    Color(hex: "#2d1e1a"),
  ]

  private struct Spec {
    let skin: Color
    let hair: Color
    let shirt: Color
    let style: Int       // 0…5 hair style
    let eyeOffset: CGFloat
    let smile: Int       // 0…3
    let hasGlasses: Bool
  }

  private var spec: Spec {
    let h = Self.hashString(personId + "|portrait")
    return Spec(
      skin:  Self.skinTones[Int(h % UInt32(Self.skinTones.count))],
      hair:  Self.hairColors[Int((h >> 3) % UInt32(Self.hairColors.count))],
      shirt: Self.shirtColors[Int((h >> 5) % UInt32(Self.shirtColors.count))],
      style: Int((h >> 7) % 6),
      eyeOffset: ((h >> 9) & 1) == 1 ? -0.8 : 0.8,
      smile: Int((h >> 11) % 4),
      hasGlasses: ((h >> 13) & 7) == 0
    )
  }

  private static func hashString(_ s: String, seed: UInt32 = 17) -> UInt32 {
    var h: UInt32 = seed
    for u in s.unicodeScalars { h = h &* 31 &+ u.value }
    return h
  }

  var body: some View {
    let s = spec
    ZStack {
      // soft background — radial gradient da shirt color
      RadialGradient(
        colors: [s.shirt.lighten(0.15), s.shirt.darken(0.35)],
        center: UnitPoint(x: 0.5, y: 0.4),
        startRadius: 0,
        endRadius: 70
      )

      // shoulders / shirt
      Ellipse().fill(s.shirt)
        .frame(width: 84, height: 44).position(x: 50, y: 100)
      Ellipse().fill(s.shirt.darken(0.20))
        .frame(width: 76, height: 36).position(x: 50, y: 102)

      // neck
      RoundedRectangle(cornerRadius: 2).fill(s.skin.darken(0.10))
        .frame(width: 12, height: 12).position(x: 50, y: 69)

      // hair back layer (per long & bun)
      if s.style == 1 {
        HairLongBack(color: s.hair)
      } else if s.style == 5 {
        Circle().fill(s.hair).frame(width: 20, height: 20).position(x: 50, y: 18)
      }

      // face
      Ellipse().fill(s.skin)
        .frame(width: 40, height: 46).position(x: 50, y: 44)

      // ears
      Ellipse().fill(s.skin.darken(0.15))
        .frame(width: 6, height: 10).position(x: 29, y: 46)
      Ellipse().fill(s.skin.darken(0.15))
        .frame(width: 6, height: 10).position(x: 71, y: 46)

      // hair top layer
      hairTop(spec: s)

      // eyebrows
      RoundedRectangle(cornerRadius: 0.75).fill(s.hair.darken(0.20))
        .frame(width: 9, height: 1.5).position(x: 42.5, y: 40.75)
      RoundedRectangle(cornerRadius: 0.75).fill(s.hair.darken(0.20))
        .frame(width: 9, height: 1.5).position(x: 57.5, y: 40.75)

      // eyes
      Circle().fill(Color(white: 0.13))
        .frame(width: 3.2, height: 3.2)
        .position(x: 42 + s.eyeOffset * 0.2, y: 45)
      Circle().fill(Color(white: 0.13))
        .frame(width: 3.2, height: 3.2)
        .position(x: 58 + s.eyeOffset * 0.2, y: 45)

      // glasses (rare)
      if s.hasGlasses {
        Group {
          Circle().stroke(Color.white.opacity(0.85), lineWidth: 1)
            .frame(width: 8, height: 8).position(x: 42, y: 45)
          Circle().stroke(Color.white.opacity(0.85), lineWidth: 1)
            .frame(width: 8, height: 8).position(x: 58, y: 45)
          Path { p in
            p.move(to: CGPoint(x: 46, y: 45))
            p.addLine(to: CGPoint(x: 54, y: 45))
          }.stroke(Color.white.opacity(0.85), lineWidth: 1)
        }
      }

      // nose hint
      Path { p in
        p.move(to: CGPoint(x: 50, y: 48))
        p.addQuadCurve(to: CGPoint(x: 51, y: 54), control: CGPoint(x: 49, y: 53))
      }.stroke(s.skin.darken(0.18).opacity(0.6), style: .init(lineWidth: 0.8, lineCap: .round))

      // mouth
      mouth(spec: s)
    }
    .frame(width: 100, height: 100)
    .scaleEffect(size / 100)
    .frame(width: size, height: size)
    .clipShape(Circle())
    .saturation(grayscale ? 0 : 1)
    .brightness(grayscale ? -0.05 : 0)
  }

  // MARK: hair top variants

  @ViewBuilder
  private func hairTop(spec s: Spec) -> some View {
    switch s.style {
    case 0: // short round cap
      Path { p in
        p.move(to: CGPoint(x: 30, y: 38))
        p.addQuadCurve(to: CGPoint(x: 50, y: 20), control: CGPoint(x: 32, y: 22))
        p.addQuadCurve(to: CGPoint(x: 70, y: 38), control: CGPoint(x: 68, y: 22))
        p.addQuadCurve(to: CGPoint(x: 50, y: 30), control: CGPoint(x: 66, y: 30))
        p.addQuadCurve(to: CGPoint(x: 30, y: 38), control: CGPoint(x: 34, y: 30))
        p.closeSubpath()
      }.fill(s.hair)
    case 1: // long front
      Path { p in
        p.move(to: CGPoint(x: 30, y: 40))
        p.addQuadCurve(to: CGPoint(x: 50, y: 20), control: CGPoint(x: 30, y: 22))
        p.addQuadCurve(to: CGPoint(x: 70, y: 40), control: CGPoint(x: 70, y: 22))
        p.addQuadCurve(to: CGPoint(x: 50, y: 32), control: CGPoint(x: 65, y: 30))
        p.addQuadCurve(to: CGPoint(x: 30, y: 40), control: CGPoint(x: 35, y: 30))
        p.closeSubpath()
      }.fill(s.hair)
    case 2: // very short
      Path { p in
        p.move(to: CGPoint(x: 34, y: 36))
        p.addQuadCurve(to: CGPoint(x: 66, y: 36), control: CGPoint(x: 50, y: 27))
      }.stroke(s.hair.opacity(0.7), style: .init(lineWidth: 1.5, lineCap: .round))
    case 3: // curly cloud
      Group {
        Circle().fill(s.hair).frame(width: 14, height: 14).position(x: 35, y: 28)
        Circle().fill(s.hair).frame(width: 14, height: 14).position(x: 44, y: 24)
        Circle().fill(s.hair).frame(width: 15, height: 15).position(x: 55, y: 24)
        Circle().fill(s.hair).frame(width: 14, height: 14).position(x: 65, y: 28)
        Circle().fill(s.hair).frame(width: 12, height: 12).position(x: 30, y: 36)
        Circle().fill(s.hair).frame(width: 12, height: 12).position(x: 70, y: 36)
      }
    case 4: // side swept
      Path { p in
        p.move(to: CGPoint(x: 28, y: 40))
        p.addQuadCurve(to: CGPoint(x: 52, y: 20), control: CGPoint(x: 30, y: 20))
        p.addQuadCurve(to: CGPoint(x: 72, y: 36), control: CGPoint(x: 70, y: 22))
        p.addQuadCurve(to: CGPoint(x: 46, y: 32), control: CGPoint(x: 55, y: 28))
        p.addQuadCurve(to: CGPoint(x: 28, y: 40), control: CGPoint(x: 34, y: 34))
        p.closeSubpath()
      }.fill(s.hair)
    default: // 5 — pulled back band
      Path { p in
        p.move(to: CGPoint(x: 32, y: 38))
        p.addQuadCurve(to: CGPoint(x: 50, y: 24), control: CGPoint(x: 34, y: 26))
        p.addQuadCurve(to: CGPoint(x: 68, y: 38), control: CGPoint(x: 66, y: 26))
        p.addQuadCurve(to: CGPoint(x: 50, y: 32), control: CGPoint(x: 60, y: 32))
        p.addQuadCurve(to: CGPoint(x: 32, y: 38), control: CGPoint(x: 40, y: 32))
        p.closeSubpath()
      }.fill(s.hair)
    }
  }

  @ViewBuilder
  private func mouth(spec s: Spec) -> some View {
    let mouthColor = s.skin.darken(s.smile == 1 || s.smile == 3 ? 0.40 : 0.35)
    switch s.smile {
    case 0:
      Path { p in
        p.move(to: CGPoint(x: 45, y: 58))
        p.addQuadCurve(to: CGPoint(x: 55, y: 58), control: CGPoint(x: 50, y: 60))
      }.stroke(mouthColor, style: .init(lineWidth: 1, lineCap: .round))
    case 1:
      Path { p in
        p.move(to: CGPoint(x: 45, y: 58))
        p.addQuadCurve(to: CGPoint(x: 55, y: 58), control: CGPoint(x: 50, y: 62))
      }.stroke(mouthColor, style: .init(lineWidth: 1.2, lineCap: .round))
    case 2:
      RoundedRectangle(cornerRadius: 0.7).fill(mouthColor)
        .frame(width: 8, height: 1.4).position(x: 50, y: 58.7)
    default:
      Path { p in
        p.move(to: CGPoint(x: 46, y: 58))
        p.addQuadCurve(to: CGPoint(x: 54, y: 58), control: CGPoint(x: 50, y: 60))
      }.stroke(mouthColor, style: .init(lineWidth: 1, lineCap: .round))
    }
  }
}

// MARK: - hair back path

private struct HairLongBack: View {
  let color: Color
  var body: some View {
    Path { p in
      // sx
      p.move(to: CGPoint(x: 22, y: 58))
      p.addQuadCurve(to: CGPoint(x: 32, y: 92), control: CGPoint(x: 20, y: 80))
      p.addLine(to: CGPoint(x: 32, y: 68))
      p.addQuadCurve(to: CGPoint(x: 22, y: 58), control: CGPoint(x: 28, y: 56))
      p.closeSubpath()
      // dx
      p.move(to: CGPoint(x: 78, y: 58))
      p.addQuadCurve(to: CGPoint(x: 68, y: 92), control: CGPoint(x: 80, y: 80))
      p.addLine(to: CGPoint(x: 68, y: 68))
      p.addQuadCurve(to: CGPoint(x: 78, y: 58), control: CGPoint(x: 72, y: 56))
      p.closeSubpath()
    }.fill(color)
  }
}

// MARK: - color tweaks

extension Color {
  /// Mix verso bianco di `amt` (0…1).
  func lighten(_ amt: Double) -> Color {
    let rgb = self.rgbComponents()
    return Color(
      red:   rgb.r + (1 - rgb.r) * amt,
      green: rgb.g + (1 - rgb.g) * amt,
      blue:  rgb.b + (1 - rgb.b) * amt
    )
  }

  /// Mix verso nero di `amt` (0…1).
  func darken(_ amt: Double) -> Color {
    let rgb = self.rgbComponents()
    return Color(
      red:   rgb.r * (1 - amt),
      green: rgb.g * (1 - amt),
      blue:  rgb.b * (1 - amt)
    )
  }

  private func rgbComponents() -> (r: Double, g: Double, b: Double) {
    let ui = UIColor(self)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    ui.getRed(&r, green: &g, blue: &b, alpha: &a)
    return (Double(r), Double(g), Double(b))
  }
}

#Preview {
  HStack {
    PortraitView(personId: "p01", size: 96)
    PortraitView(personId: "p07", size: 72)
    PortraitView(personId: "p18", size: 52)
  }.padding().background(Color.black)
}
