import SwiftUI

/// Sfondo "Deep Space" — black + radial vignette + starfield + sottile nebula wash.
/// Equivalente Swift di `Background` + `Starfield` + `NoiseGrain` del prototipo.
struct DeepSpaceBackground: View {
  enum Theme { case nocturne, aurora, dusk }
  var theme: Theme = .nocturne

  var body: some View {
    ZStack {
      Color.black

      // vignette (warm/cool shift in base al tema)
      RadialGradient(
        colors: vignetteColors,
        center: UnitPoint(x: 0.5, y: 0.45),
        startRadius: 0,
        endRadius: 600
      )
      .ignoresSafeArea()

      Starfield(count: 70)
        .blendMode(.plusLighter)

      // faint nebula wash, blurred
      RadialGradient(
        colors: [nebulaColor, .clear],
        center: UnitPoint(x: 0.7, y: 0.8),
        startRadius: 0,
        endRadius: 380
      )
      .blur(radius: 30)
      .opacity(0.85)
      .allowsHitTesting(false)
    }
    .ignoresSafeArea()
  }

  private var vignetteColors: [Color] {
    switch theme {
    case .aurora:   return [Color(hex: "#050510"), Color(hex: "#020205"), .black]
    case .dusk:     return [Color(hex: "#0a0609"), Color(hex: "#040203"), .black]
    case .nocturne: return [Color(hex: "#04070e"), Color(hex: "#020308"), .black]
    }
  }

  private var nebulaColor: Color {
    switch theme {
    case .aurora:   return Color.fromOKLCH(l: 0.32, c: 0.05, h: 260, alpha: 0.12)
    case .dusk:     return Color.fromOKLCH(l: 0.30, c: 0.04, h: 20,  alpha: 0.10)
    case .nocturne: return Color.fromOKLCH(l: 0.28, c: 0.04, h: 220, alpha: 0.08)
    }
  }
}

private struct Starfield: View {
  let count: Int

  private struct Star: Hashable {
    let x: CGFloat       // 0…1
    let y: CGFloat       // 0…1
    let size: CGFloat
    let opacity: Double
    let delay: Double
  }

  // Stelle stabili (PRNG seeded a 42 come nel design)
  private static func generate(count: Int) -> [Star] {
    var s: UInt32 = 42
    func r() -> Double {
      s = s &* 1664525 &+ 1013904223
      return Double(s) / 4294967296.0
    }
    return (0..<count).map { _ in
      Star(
        x: CGFloat(r()),
        y: CGFloat(r()),
        size: CGFloat(0.4 + r() * 1.3),
        opacity: 0.1 + r() * 0.45,
        delay: r() * 5
      )
    }
  }

  private let stars: [Star]
  init(count: Int) {
    self.count = count
    self.stars = Self.generate(count: count)
  }

  var body: some View {
    GeometryReader { geo in
      TimelineView(.animation(minimumInterval: 1.0 / 12, paused: false)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        ZStack {
          ForEach(stars, id: \.self) { star in
            let phase = sin((t / (4 + star.delay)) * .pi * 2 + star.delay)
            let twinkle = 0.7 + 0.3 * phase
            Circle()
              .fill(Color.white.opacity(star.opacity * twinkle))
              .frame(width: star.size, height: star.size)
              .shadow(color: star.size > 1 ? .white.opacity(0.5) : .clear, radius: star.size * 2)
              .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
          }
        }
      }
    }
    .allowsHitTesting(false)
  }
}

#Preview {
  DeepSpaceBackground()
    .frame(width: 402, height: 874)
}
