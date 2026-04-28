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
  var onSelfLongPress: () -> Void = {}
  var onProposeTier: (DemoPerson, FriendshipTier) -> Void = { _, _ in }

  @State private var drag: DragState? = nil
  @State private var zoomLevel: ZoomLevel = .full
  @State private var pinchInProgress: Bool = false
  @State private var zoomDragStart: ZoomLevel? = nil
  @State private var showZoomSlider: Bool = false
  @State private var zoomSliderHideTask: Task<Void, Never>? = nil

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
      let cy = H * 0.52
      // Espande lateralmente: l'anello esterno tocca quasi i bordi.
      let maxR = min(W, H) * 0.56
      // Solo follow mutuali finiscono sugli anelli; gli asimmetrici sono asteroidi.
      let mutuals = people.filter(\.isMutual)
      let counts = Dictionary(grouping: mutuals, by: \.tier).mapValues(\.count)
      let placements = OrbitalLayout.placements(for: mutuals.map { ($0.id, $0.tier) })
      let placementByPerson = Dictionary(uniqueKeysWithValues: placements.map { ($0.personId, $0) })

      ZStack {
        // 1. anelli (illuminati se ghostTier li attraversa). Nebula in dezoom
        // diventa una fascia diffusa, non un anello orbitale classico.
        ForEach(FriendshipTier.allCases.filter { $0.isVisible(at: zoomLevel) && !($0 == .nebula && zoomLevel == .asteroids) }, id: \.self) { tier in
          OrbitalRing(
            tier: tier,
            diameter: tier.ringRadius(at: zoomLevel) * maxR * 2,
            count: counts[tier, default: 0],
            active: drag?.ghostTier == tier
          )
          .position(x: cx, y: cy)
          .transition(.opacity)
        }

        if zoomLevel == .asteroids {
          nebulaBand(cx: cx, cy: cy, maxR: maxR)
        }

        // 2. self center
        SelfCenterView(
          mood: me.mood,
          size: selfCenterSize,
          hasActiveVibe: me.hasActiveVibe
        )
        .position(x: cx, y: cy)
        .zIndex(15)
        .onTapGesture(perform: onSelfTap)
        .onLongPressGesture(minimumDuration: 0.45) {
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          onSelfLongPress()
        }

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

        // 4. bolle (solo mutuali, solo tier visibili al livello corrente)
        ForEach(mutuals) { p in
          if let placement = placementByPerson[p.id],
             placement.tier.isVisible(at: zoomLevel),
             !(placement.tier == .nebula && zoomLevel == .asteroids) {
            let isDragging = drag?.personId == p.id
            let effectiveTier = isDragging ? (drag?.ghostTier ?? placement.tier) : placement.tier
            let xy = isDragging
              ? (drag?.location ?? polarToXY(tier: effectiveTier, angle: placement.angle, cx: cx, cy: cy, maxR: maxR))
              : polarToXY(tier: effectiveTier, angle: placement.angle, cx: cx, cy: cy, maxR: maxR)
            let size = effectiveTier.bubbleSize(at: zoomLevel)
            let hitSize = max(size, 56)
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
            .frame(width: hitSize, height: hitSize)
            .contentShape(Circle())
            .position(x: xy.x, y: xy.y)
            .zIndex(isDragging ? 50 : 10)
            .animation(isDragging ? nil : .spring(response: 0.55, dampingFraction: 0.78), value: effectiveTier)
            .animation(.easeInOut(duration: 0.35), value: zoomLevel)
            .gesture(bubbleGesture(for: p, cx: cx, cy: cy, maxR: maxR))
            .onTapGesture {
              HapticEngine.tap(for: p.tier)
              onBubbleTap(p)
            }
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
          .haloGlass(in: Capsule(), interactive: false)
          .position(x: cx, y: 32)
          .zIndex(60)
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
      .contentShape(Rectangle())
      .animation(.easeInOut(duration: 0.2), value: drag?.ghostTier)
      .animation(.spring(response: 0.55, dampingFraction: 0.82), value: zoomLevel)
      .gesture(pinchGesture)
      .simultaneousGesture(
        fieldZoomDragGesture(
          mutuals: mutuals,
          placementByPerson: placementByPerson,
          cx: cx,
          cy: cy,
          maxR: maxR
        )
      )
      .overlay(alignment: .trailing) {
        ZoomSlider(level: zoomLevelBinding)
          .padding(.trailing, 14)
          .opacity(showZoomSlider ? 1 : 0)
          .allowsHitTesting(showZoomSlider)
          .animation(.easeInOut(duration: 0.18), value: showZoomSlider)
      }
      .onChange(of: zoomLevel) { _, newValue in onZoomChange(newValue) }
    }
    .coordinateSpace(name: fieldSpace)
    .onDisappear {
      zoomSliderHideTask?.cancel()
    }
  }

  private var zoomLevelBinding: Binding<ZoomLevel> {
    Binding(
      get: { zoomLevel },
      set: {
        revealZoomSlider()
        zoomLevel = $0
      }
    )
  }

  @ViewBuilder
  private func nebulaBand(cx: CGFloat, cy: CGFloat, maxR: CGFloat) -> some View {
    let nebulaPeople = people.filter { $0.isMutual && $0.tier == .nebula }

    ZStack {
      ForEach([0.66, 0.76, 0.86, 0.96], id: \.self) { radius in
        Circle()
          .stroke(
            Color.white.opacity(radius == 0.76 ? 0.11 : 0.06),
            style: StrokeStyle(lineWidth: 1, dash: [2, 9], dashPhase: radius * 17)
          )
          .frame(width: maxR * CGFloat(radius) * 2, height: maxR * CGFloat(radius) * 2)
          .position(x: cx, y: cy)
      }

      ForEach(nebulaPeople) { p in
        let xy = nebulaBeltPosition(for: p, cx: cx, cy: cy, maxR: maxR)
        let size = p.tier.bubbleSize(at: zoomLevel)
        let hitSize = max(size, 56)

        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !pulsing)) { ctx in
          let seed = nebulaSeed(for: p.id)
          let t = ctx.date.timeIntervalSinceReferenceDate
          let dx = CGFloat(sin((t / (8.5 + seed * 3.5)) * .pi * 2)) * 5
          let dy = CGFloat(cos((t / (10.5 + seed * 4.0)) * .pi * 2)) * 4

          BubbleView(
            personId: p.id,
            handle: p.handle,
            mood: p.mood,
            size: size,
            hasNew: p.hasNew,
            showName: false,
            pulsing: pulsing,
            hasActiveVibe: p.hasActiveVibe,
            lastPostAt: p.lastPostAt
          )
          .frame(width: hitSize, height: hitSize)
          .contentShape(Circle())
          .offset(x: dx, y: dy)
          .onTapGesture {
            HapticEngine.tap(for: p.tier)
            onBubbleTap(p)
          }
        }
        .frame(width: hitSize, height: hitSize)
        .position(x: xy.x, y: xy.y)
        .zIndex(8)
      }
    }
    .transition(.opacity)
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
          revealZoomSlider()
          zoomLevel = zoomLevel.zoomedIn()
        } else if scale < 0.78 {
          pinchInProgress = true
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
          revealZoomSlider()
          zoomLevel = zoomLevel.zoomedOut()
        }
      }
      .onEnded { _ in
        pinchInProgress = false
      }
  }

  private func fieldZoomDragGesture(
    mutuals: [DemoPerson],
    placementByPerson: [String: OrbitalLayout.Placement],
    cx: CGFloat,
    cy: CGFloat,
    maxR: CGFloat
  ) -> some Gesture {
    DragGesture(minimumDistance: 18, coordinateSpace: .named(fieldSpace))
      .onChanged { value in
        guard drag == nil else { return }
        guard !isNearBubble(
          value.startLocation,
          mutuals: mutuals,
          placementByPerson: placementByPerson,
          cx: cx,
          cy: cy,
          maxR: maxR
        ) else { return }

        let dx = value.translation.width
        let dy = value.translation.height
        guard abs(dy) > abs(dx) * 1.25 else { return }

        let start = zoomDragStart ?? zoomLevel
        zoomDragStart = start
        let steps = Int((dy / 58).rounded())
        let raw = min(
          max(start.rawValue + steps, ZoomLevel.innerOnly.rawValue),
          ZoomLevel.asteroids.rawValue
        )
        guard let next = ZoomLevel(rawValue: raw), next != zoomLevel else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        revealZoomSlider()
        zoomLevel = next
      }
      .onEnded { _ in
        zoomDragStart = nil
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

  private func nebulaBeltPosition(for person: DemoPerson, cx: CGFloat, cy: CGFloat, maxR: CGFloat) -> CGPoint {
    let seed = nebulaSeed(for: person.id)
    let angle = Double(OrbitalLayout.angleSeedFor(person.id, tier: .nebula, seed: 19)) * .pi / 180.0
    let radius = maxR * CGFloat(0.68 + seed * 0.26)
    return CGPoint(x: cx + CGFloat(cos(angle)) * radius, y: cy + CGFloat(sin(angle)) * radius)
  }

  private func nebulaSeed(for id: String) -> Double {
    var h: UInt32 = 2166136261
    for u in id.unicodeScalars { h = (h ^ u.value) &* 16777619 }
    return Double(h % 1000) / 1000.0
  }

  private func isNearBubble(
    _ location: CGPoint,
    mutuals: [DemoPerson],
    placementByPerson: [String: OrbitalLayout.Placement],
    cx: CGFloat,
    cy: CGFloat,
    maxR: CGFloat
  ) -> Bool {
    for p in mutuals {
      guard let placement = placementByPerson[p.id], placement.tier.isVisible(at: zoomLevel) else { continue }
      let pos = (placement.tier == .nebula && zoomLevel == .asteroids)
        ? nebulaBeltPosition(for: p, cx: cx, cy: cy, maxR: maxR)
        : polarToXY(tier: placement.tier, angle: placement.angle, cx: cx, cy: cy, maxR: maxR)
      let radius = max(placement.tier.bubbleSize(at: zoomLevel), 56) / 2 + 12
      if hypot(location.x - pos.x, location.y - pos.y) <= radius { return true }
    }
    return false
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

  private func revealZoomSlider() {
    zoomSliderHideTask?.cancel()
    withAnimation(.easeInOut(duration: 0.18)) {
      showZoomSlider = true
    }
    zoomSliderHideTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: 1_500_000_000)
      withAnimation(.easeInOut(duration: 0.24)) {
        showZoomSlider = false
      }
    }
  }
}
