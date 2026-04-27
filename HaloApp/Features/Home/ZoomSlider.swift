import SwiftUI

/// Slider verticale auto-hide per cambiare ZoomLevel.
/// Compare quando l'utente lo tocca o quando il livello cambia, e si nasconde
/// dopo 2 secondi di inattività.
struct ZoomSlider: View {
  @Binding var level: ZoomLevel
  @State private var visible: Bool = false
  @State private var hideTask: Task<Void, Never>? = nil

  private let trackHeight: CGFloat = 168
  private let dotSize: CGFloat = 10

  var body: some View {
    VStack(spacing: 0) {
      ForEach(ZoomLevel.allCases.reversed(), id: \.self) { lvl in
        let isCurrent = (lvl == level)
        Button {
          select(lvl)
        } label: {
          ZStack {
            Circle()
              .fill(isCurrent ? Color.white : Color.white.opacity(0.35))
              .frame(width: isCurrent ? dotSize + 2 : dotSize - 2,
                     height: isCurrent ? dotSize + 2 : dotSize - 2)
              .shadow(color: isCurrent ? .white.opacity(0.55) : .clear, radius: 4)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .frame(width: 28, height: trackHeight)
    .background(
      Capsule()
        .fill(Color.black.opacity(0.32))
        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.5))
    )
    .opacity(visible ? 1 : 0)
    .scaleEffect(visible ? 1 : 0.9)
    .animation(.easeInOut(duration: 0.25), value: visible)
    .onAppear { show() }
    .onChange(of: level) { _, _ in show() }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Zoom orbital field")
  }

  private func select(_ lvl: ZoomLevel) {
    level = lvl
    show()
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
