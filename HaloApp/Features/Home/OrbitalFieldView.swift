import SwiftUI
import UIKit
import HaloShared

/// Campo orbitale "Deep Space": 4 anelli hairline + bolle portrait + self center.
/// Drag radiale di una bolla → `onProposeTier(person, ghostTier)`.
/// Tap singolo → `onBubbleTap(person)`.
struct OrbitalFieldView: View {
  let people: [DemoPerson]
  let me: DemoPerson
  var pulsing: Bool = true
  var onBubbleTap: (DemoPerson) -> Void = { _ in }
  var onSelfTap: () -> Void = {}
  var onProposeTier: (DemoPerson, FriendshipTier) -> Void = { _, _ in }

  @State private var drag: DragState? = nil

  private struct DragState: Equatable {
    var personId: String
    var ghostTier: FriendshipTier
    var location: CGPoint
  }

  private let fieldSpace = "halo.orbitalField"

  var body: some View {
    GeometryReader { geo in
      let W = geo.size.width
      let H = geo.size.height
      let cx = W / 2
      let cy = H / 2
      // Espande lateralmente: l'anello esterno tocca quasi i bordi.
      let maxR = min(W, H) * 0.56
      let placements = OrbitalLayout.placements(for: people.map { ($0.id, $0.tier) })
      let placementByPerson = Dictionary(uniqueKeysWithValues: placements.map { ($0.personId, $0) })

      ZStack {
        // 1. anelli (illuminati se ghostTier li attraversa)
        ForEach(FriendshipTier.allCases, id: \.self) { tier in
          OrbitalRing(
            tier: tier,
            diameter: tier.ringRadius * maxR * 2,
            active: drag?.ghostTier == tier
          )
          .position(x: cx, y: cy)
        }

        // 2. self center
        SelfCenterView(mood: me.mood, size: 128, onTap: onSelfTap)
          .position(x: cx, y: cy)
          .zIndex(15)

        // 3. ghost outline nella posizione originale durante un drag
        if let d = drag,
           let original = placementByPerson[d.personId],
           d.ghostTier != original.tier {
          let pos = polarToXY(tier: original.tier, angle: original.angle, cx: cx, cy: cy, maxR: maxR)
          let s = original.tier.bubbleSize
          Circle()
            .stroke(Color.white.opacity(0.4), style: .init(lineWidth: 1, dash: [3, 3]))
            .frame(width: s, height: s)
            .position(x: pos.x, y: pos.y)
        }

        // 4. bolle
        ForEach(people) { p in
          if let placement = placementByPerson[p.id] {
            let isDragging = drag?.personId == p.id
            let effectiveTier = isDragging ? (drag?.ghostTier ?? placement.tier) : placement.tier
            let xy = isDragging
              ? (drag?.location ?? polarToXY(tier: effectiveTier, angle: placement.angle, cx: cx, cy: cy, maxR: maxR))
              : polarToXY(tier: effectiveTier, angle: placement.angle, cx: cx, cy: cy, maxR: maxR)
            let size = effectiveTier.bubbleSize
            BubbleView(
              personId: p.id,
              handle: p.handle,
              mood: p.mood,
              size: size,
              hasNew: p.hasNew,
              showName: effectiveTier == .inner || effectiveTier == .close,
              pulsing: pulsing
            )
            .position(x: xy.x, y: xy.y)
            .zIndex(isDragging ? 50 : 10)
            .animation(isDragging ? nil : .spring(response: 0.55, dampingFraction: 0.78), value: effectiveTier)
            .gesture(bubbleGesture(for: p, cx: cx, cy: cy, maxR: maxR))
            .onTapGesture { onBubbleTap(p) }
          }
        }

        // 5. hint pill
        if let d = drag,
           let original = placementByPerson[d.personId],
           d.ghostTier != original.tier {
          HStack(spacing: 6) {
            Text("→ sposta in")
              .foregroundStyle(Color.white.opacity(0.8))
            Text(d.ghostTier.label)
              .fontWeight(.semibold)
              .foregroundStyle(.white)
          }
          .font(.system(size: 13, weight: .medium))
          .kerning(-0.1)
          .padding(.horizontal, 16).padding(.vertical, 8)
          .background(.black.opacity(0.6), in: Capsule())
          .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
          .background(.ultraThinMaterial, in: Capsule())
          .position(x: cx, y: 32)
          .zIndex(60)
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
      .animation(.easeInOut(duration: 0.2), value: drag?.ghostTier)
    }
    .coordinateSpace(name: fieldSpace)
  }

  // MARK: helpers

  private func polarToXY(tier: FriendshipTier, angle: Double, cx: CGFloat, cy: CGFloat, maxR: CGFloat) -> CGPoint {
    let r = tier.ringRadius * Double(maxR)
    return CGPoint(x: cx + CGFloat(cos(angle) * r), y: cy + CGFloat(sin(angle) * r))
  }

  private func nearestTier(to location: CGPoint, cx: CGFloat, cy: CGFloat, maxR: CGFloat) -> FriendshipTier {
    let d = hypot(location.x - cx, location.y - cy)
    var best: FriendshipTier = .nebula
    var bestDiff: CGFloat = .infinity
    for t in FriendshipTier.allCases {
      let r = CGFloat(t.ringRadius) * maxR
      let diff = abs(d - r)
      if diff < bestDiff { bestDiff = diff; best = t }
    }
    return best
  }

  private func bubbleGesture(for person: DemoPerson, cx: CGFloat, cy: CGFloat, maxR: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 6, coordinateSpace: .named(fieldSpace))
      .onChanged { value in
        let target = nearestTier(to: value.location, cx: cx, cy: cy, maxR: maxR)
        if drag?.ghostTier != target {
          UISelectionFeedbackGenerator().selectionChanged()
        }
        drag = DragState(personId: person.id, ghostTier: target, location: value.location)
      }
      .onEnded { _ in
        guard let d = drag else { return }
        if d.personId == person.id, d.ghostTier != person.tier {
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          onProposeTier(person, d.ghostTier)
        }
        drag = nil
      }
  }
}
