import SwiftUI
import UIKit
import HaloShared

/// Campo orbitale "Deep Space": 4 anelli hairline + bolle portrait + self center.
/// Drag radiale di una bolla → `onProposeTier(person, ghostTier)`.
/// Tap singolo → `onBubbleTap(person)`.
/// Pinch → cambia `ZoomLevel` (innerOnly · innerClose · full · asteroids).
struct OrbitalFieldView: View {
  let people: [DemoPerson]
  let me: DemoPerson
  var pulsing: Bool = true
  var onBubbleTap: (DemoPerson) -> Void = { _ in }
  var onSelfTap: () -> Void = {}
  var onProposeTier: (DemoPerson, FriendshipTier) -> Void = { _, _ in }

  @State private var drag: DragState? = nil
  @State private var zoomLevel: ZoomLevel = .full
  @State private var pinchInProgress: Bool = false

  /// Espone il livello corrente al parent (per uno slider esterno o per AsteroidBeltView).
  var onZoomChange: (ZoomLevel) -> Void = { _ in }

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
        ForEach(FriendshipTier.allCases.filter { $0.isVisible(at: zoomLevel) }, id: \.self) { tier in
          OrbitalRing(
            tier: tier,
            diameter: tier.ringRadius(at: zoomLevel) * maxR * 2,
            active: drag?.ghostTier == tier
          )
          .position(x: cx, y: cy)
          .transition(.opacity)
        }

        // 2. self center
        SelfCenterView(mood: me.mood, size: selfCenterSize)
          .position(x: cx, y: cy)
          .zIndex(15)
          .onTapGesture(perform: onSelfTap)

        // 3. ghost outline nella posizione originale durante un drag
        if let d = drag,
           let original = placementByPerson[d.personId],
           d.ghostTier != original.tier {
          let pos = polarToXY(tier: original.tier, angle: original.angle, cx: cx, cy: cy, maxR: maxR)
          let s = original.tier.bubbleSize(at: zoomLevel)
          Circle()
            .stroke(Color.white.opacity(0.4), style: .init(lineWidth: 1, dash: [3, 3]))
            .frame(width: s, height: s)
            .position(x: pos.x, y: pos.y)
        }

        // 4. bolle (solo tier visibili al livello corrente)
        ForEach(people) { p in
          if let placement = placementByPerson[p.id], placement.tier.isVisible(at: zoomLevel) {
            let isDragging = drag?.personId == p.id
            let effectiveTier = isDragging ? (drag?.ghostTier ?? placement.tier) : placement.tier
            let xy = isDragging
              ? (drag?.location ?? polarToXY(tier: effectiveTier, angle: placement.angle, cx: cx, cy: cy, maxR: maxR))
              : polarToXY(tier: effectiveTier, angle: placement.angle, cx: cx, cy: cy, maxR: maxR)
            let size = effectiveTier.bubbleSize(at: zoomLevel)
            BubbleView(
              personId: p.id,
              handle: p.handle,
              mood: p.mood,
              size: size,
              hasNew: p.hasNew,
              showName: effectiveTier == .inner || effectiveTier == .close,
              pulsing: pulsing,
              hasActiveVibe: p.hasActiveVibe,
              lastPostAt: p.lastPostAt
            )
            .position(x: xy.x, y: xy.y)
            .zIndex(isDragging ? 50 : 10)
            .animation(isDragging ? nil : .spring(response: 0.55, dampingFraction: 0.78), value: effectiveTier)
            .animation(.easeInOut(duration: 0.35), value: zoomLevel)
            .gesture(bubbleGesture(for: p, cx: cx, cy: cy, maxR: maxR))
            .onTapGesture { onBubbleTap(p) }
            .transition(.scale(scale: 0.6).combined(with: .opacity))
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
      .animation(.spring(response: 0.55, dampingFraction: 0.82), value: zoomLevel)
      .gesture(pinchGesture)
      .overlay(alignment: .trailing) {
        ZoomSlider(level: zoomLevelBinding)
          .padding(.trailing, 14)
      }
      .onChange(of: zoomLevel) { _, newValue in onZoomChange(newValue) }
    }
    .coordinateSpace(name: fieldSpace)
  }

  private var zoomLevelBinding: Binding<ZoomLevel> {
    Binding(
      get: { zoomLevel },
      set: { zoomLevel = $0 }
    )
  }

  // MARK: gestures

  /// Pinch out (>1) → zoom in (innerClose, innerOnly).
  /// Pinch in (<1) → zoom out (asteroids).
  private var pinchGesture: some Gesture {
    MagnificationGesture(minimumScaleDelta: 0.05)
      .onChanged { scale in
        guard !pinchInProgress else { return }
        if scale > 1.25 {
          pinchInProgress = true
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
          zoomLevel = zoomLevel.zoomedIn()
        } else if scale < 0.78 {
          pinchInProgress = true
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
          zoomLevel = zoomLevel.zoomedOut()
        }
      }
      .onEnded { _ in
        pinchInProgress = false
      }
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

  // MARK: helpers

  private var selfCenterSize: CGFloat {
    switch zoomLevel {
    case .innerOnly:  return 168
    case .innerClose: return 144
    case .full:       return 128
    case .asteroids:  return 96
    }
  }

  private func polarToXY(tier: FriendshipTier, angle: Double, cx: CGFloat, cy: CGFloat, maxR: CGFloat) -> CGPoint {
    let r = tier.ringRadius(at: zoomLevel) * Double(maxR)
    return CGPoint(x: cx + CGFloat(cos(angle) * r), y: cy + CGFloat(sin(angle) * r))
  }

  private func nearestTier(to location: CGPoint, cx: CGFloat, cy: CGFloat, maxR: CGFloat) -> FriendshipTier {
    let d = hypot(location.x - cx, location.y - cy)
    var best: FriendshipTier = .nebula
    var bestDiff: CGFloat = .infinity
    for t in FriendshipTier.allCases where t.isVisible(at: zoomLevel) {
      let r = CGFloat(t.ringRadius(at: zoomLevel)) * maxR
      let diff = abs(d - r)
      if diff < bestDiff { bestDiff = diff; best = t }
    }
    return best
  }
}
