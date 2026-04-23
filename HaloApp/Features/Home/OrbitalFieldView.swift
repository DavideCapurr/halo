import SwiftUI
import HaloShared

/// Step 3 + 8: canvas con 4 anelli + bolle + drag-to-tier.
/// L'implementazione reale arriverà con HomeViewModel; per ora è uno stub visuale.
struct OrbitalFieldView: View {
  let placements: [OrbitalLayout.Placement]
  let vibesByUser: [UUID: Vibe]
  let handlesByUser: [UUID: String]

  var body: some View {
    GeometryReader { geo in
      let side = min(geo.size.width, geo.size.height)
      let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

      TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        ZStack {
          // Anelli
          ForEach(FriendshipTier.allCases, id: \.self) { tier in
            OrbitalRing(tier: tier, diameter: side * tier.ringRadius * 2)
          }

          // Bolle
          ForEach(placements, id: \.self) { p in
            let handle = handlesByUser[p.userId] ?? "?"
            let vibe = vibesByUser[p.userId]
            let phase = (t.truncatingRemainder(dividingBy: 2.4)) / 2.4
            BubbleView(
              handle: handle,
              colorHex: vibe?.colorHex,
              size: side * 0.09,
              pulsePhase: phase
            )
            .position(
              x: center.x + p.position.x * side * 0.5,
              y: center.y + p.position.y * side * 0.5
            )
          }
        }
      }
    }
    .background(HaloTheme.background)
  }
}
