import SwiftUI
import HaloShared

/// 6 reazioni emotive di Halo come glyph SVG-style: pulse, glow, echo, spark, drift, hush.
/// Niente emoji — design choice esplicita.
struct ReactionGlyph: View {
  let kind: ReactionKind
  var size: CGFloat = 22
  var color: Color = SwarmHalo.ink

  var body: some View {
    Canvas { ctx, _ in
      let scale = size / 24
      ctx.scaleBy(x: scale, y: scale)
      switch kind {
      case .pulse:  drawPulse(in: &ctx)
      case .glow:   drawGlow(in: &ctx)
      case .echo:   drawEcho(in: &ctx)
      case .spark:  drawSpark(in: &ctx)
      case .drift:  drawDrift(in: &ctx)
      case .hush:   drawHush(in: &ctx)
      }
    }
    .frame(width: size, height: size)
    .accessibilityLabel(Text(kind.rawValue))
  }

  private var stroke: GraphicsContext.Shading { .color(color) }

  private func drawPulse(in ctx: inout GraphicsContext) {
    let c = CGPoint(x: 12, y: 12)
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 3.2, y: c.y - 3.2, width: 6.4, height: 6.4)), with: stroke)
    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 7.5, y: c.y - 7.5, width: 15, height: 15)),
               with: .color(color.opacity(0.6)), lineWidth: 1.5)
    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 10.5, y: c.y - 10.5, width: 21, height: 21)),
               with: .color(color.opacity(0.25)), lineWidth: 1.5)
  }

  private func drawGlow(in ctx: inout GraphicsContext) {
    let c = CGPoint(x: 12, y: 12)
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8)), with: stroke)
    for i in 0..<8 {
      let a = Double(i) * .pi / 4
      var p = Path()
      p.move(to: CGPoint(x: c.x + cos(a) * 7, y: c.y + sin(a) * 7))
      p.addLine(to: CGPoint(x: c.x + cos(a) * 10, y: c.y + sin(a) * 10))
      ctx.stroke(p, with: stroke, style: .init(lineWidth: 1.5, lineCap: .round))
    }
  }

  private func drawEcho(in ctx: inout GraphicsContext) {
    var outer = Path()
    outer.addArc(center: CGPoint(x: 12, y: 12), radius: 7,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
    ctx.stroke(outer, with: stroke, style: .init(lineWidth: 1.5, lineCap: .round))

    var inner = Path()
    inner.addArc(center: CGPoint(x: 12, y: 12), radius: 4,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
    ctx.stroke(inner, with: .color(color.opacity(0.7)), style: .init(lineWidth: 1.5, lineCap: .round))

    ctx.fill(Path(ellipseIn: CGRect(x: 10.8, y: 10.8, width: 2.4, height: 2.4)), with: stroke)
  }

  private func drawSpark(in ctx: inout GraphicsContext) {
    var p = Path()
    p.move(to: CGPoint(x: 12, y: 3))
    p.addLine(to: CGPoint(x: 13.2, y: 10.8))
    p.addLine(to: CGPoint(x: 21,   y: 12))
    p.addLine(to: CGPoint(x: 13.2, y: 13.2))
    p.addLine(to: CGPoint(x: 12,   y: 21))
    p.addLine(to: CGPoint(x: 10.8, y: 13.2))
    p.addLine(to: CGPoint(x: 3,    y: 12))
    p.addLine(to: CGPoint(x: 10.8, y: 10.8))
    p.closeSubpath()
    ctx.fill(p, with: stroke)
  }

  private func drawDrift(in ctx: inout GraphicsContext) {
    var p = Path()
    p.move(to: CGPoint(x: 4, y: 16))
    p.addCurve(
      to: CGPoint(x: 20, y: 10),
      control1: CGPoint(x: 7, y: 8),
      control2: CGPoint(x: 13, y: 18)
    )
    ctx.stroke(p, with: stroke, style: .init(lineWidth: 1.5, lineCap: .round))
    ctx.fill(Path(ellipseIn: CGRect(x: 18.5, y: 8.5, width: 3, height: 3)), with: stroke)
  }

  private func drawHush(in ctx: inout GraphicsContext) {
    // crescent: outer disk minus shifted inner disk
    var crescent = Path(ellipseIn: CGRect(x: 8, y: 4, width: 16, height: 16))
    let cut = Path(ellipseIn: CGRect(x: 10, y: 5, width: 12, height: 12))
    crescent.addPath(cut)
    ctx.fill(crescent, with: stroke, style: .init(eoFill: true))
  }
}

#Preview {
  HStack(spacing: 12) {
    ForEach(ReactionKind.allCases, id: \.self) { k in
      ReactionGlyph(kind: k, size: 28)
    }
  }
  .padding()
  .background(SwarmHalo.background)
}
