import SwiftUI
import UIKit

/// Slider verticale auto-hide per cambiare ZoomLevel.
/// Trascinamento e tap fanno snap sul livello più vicino; la barra si nasconde
/// dopo 2 secondi di inattività.
struct ZoomSlider: View {
  @Binding var level: ZoomLevel
  @State private var visible: Bool = false
  @State private var hideTask: Task<Void, Never>? = nil

  private let trackHeight: CGFloat = 178
  private let controlWidth: CGFloat = 42
  private let handleSize: CGFloat = 24
  private let tickSize: CGFloat = 5
  private let levels = Array(ZoomLevel.allCases.reversed())

  var body: some View {
    GeometryReader { geo in
      let y = yPosition(for: level, height: geo.size.height)

      ZStack(alignment: .top) {
        Capsule()
          .fill(.ultraThinMaterial)
          .frame(width: 22, height: geo.size.height)
          .overlay(Capsule().strokeBorder(HaloInk.creamHair, lineWidth: 0.6))
          .position(x: geo.size.width / 2, y: geo.size.height / 2)

        Capsule()
          .fill(
            LinearGradient(
              colors: [HaloInk.bronze.opacity(0.60), HaloInk.creamWhisper],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(width: 4, height: max(0, y - handleSize / 2))
          .position(x: geo.size.width / 2, y: max(0, y / 2 - handleSize / 4))

        ForEach(levels, id: \.self) { lvl in
          Circle()
            .fill(lvl == level ? HaloInk.cream : HaloInk.creamMute)
            .frame(width: lvl == level ? tickSize + 2 : tickSize,
                   height: lvl == level ? tickSize + 2 : tickSize)
            .position(x: geo.size.width / 2, y: yPosition(for: lvl, height: geo.size.height))
        }

        ZStack {
          Circle()
            .fill(HaloInk.cream)
          Circle()
            .fill(HaloInk.bronze.opacity(0.18))
            .frame(width: handleSize - 8, height: handleSize - 8)
        }
          .frame(width: handleSize, height: handleSize)
          .shadow(color: HaloInk.bronzeGlow, radius: 9)
          .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
          .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 0.5))
          .position(x: geo.size.width / 2, y: y)
          .animation(.spring(response: 0.28, dampingFraction: 0.8), value: level)
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            updateLevel(at: value.location.y, height: geo.size.height)
            show()
          }
          .onEnded { value in
            updateLevel(at: value.location.y, height: geo.size.height)
            show()
          }
      )
    }
    .frame(width: controlWidth, height: trackHeight)
    .opacity(visible ? 1 : 0)
    .scaleEffect(visible ? 1 : 0.92)
    .animation(.easeInOut(duration: 0.25), value: visible)
    .onAppear { show() }
    .onChange(of: level) { _, _ in show() }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Zoom orbital field")
    .accessibilityValue(level.accessibilityLabel)
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment:
        select(level.zoomedOut())
      case .decrement:
        select(level.zoomedIn())
      @unknown default:
        break
      }
    }
  }

  private func select(_ lvl: ZoomLevel) {
    guard level != lvl else {
      show()
      return
    }
    UISelectionFeedbackGenerator().selectionChanged()
    level = lvl
    show()
  }

  private func updateLevel(at rawY: CGFloat, height: CGFloat) {
    let y = min(max(rawY, handleSize / 2), height - handleSize / 2)
    let step = (height - handleSize) / CGFloat(max(levels.count - 1, 1))
    let index = Int(((y - handleSize / 2) / step).rounded())
    let clamped = min(max(index, 0), levels.count - 1)
    select(levels[clamped])
  }

  private func yPosition(for lvl: ZoomLevel, height: CGFloat) -> CGFloat {
    guard let index = levels.firstIndex(of: lvl), levels.count > 1 else {
      return height / 2
    }
    let step = (height - handleSize) / CGFloat(levels.count - 1)
    return handleSize / 2 + CGFloat(index) * step
  }

  private func show() {
    visible = true
    hideTask?.cancel()
    hideTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      if !Task.isCancelled {
        visible = false
      }
    }
  }
}

private extension ZoomLevel {
  var accessibilityLabel: String {
    switch self {
    case .innerOnly:  return "solo inner"
    case .innerClose: return "inner e close"
    case .full:       return "inner, close, orbita"
    case .asteroids:  return "tutto il halo"
    }
  }
}
