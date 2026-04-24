import SwiftUI
import HaloShared

/// BottomBar: glass capsule con 5 slot (orbita / feed / compose / pulse / profile).
/// Il compose centrale è una bolla pulsante colorata col mood corrente.
struct BottomBarView: View {
  let selfMood: Mood
  var onCompose: () -> Void = {}
  var onOrbit: () -> Void = {}
  var onFeed: () -> Void = {}
  var onPulse: () -> Void = {}
  var onProfile: () -> Void = {}

  var body: some View {
    HStack(spacing: 18) {
      iconButton("circle.dotted", action: onOrbit)
      iconButton("text.alignleft", action: onFeed)
      composeButton()
      iconButton("list.dash", action: onPulse)
      iconButton("person.circle", action: onProfile)
    }
    .padding(.horizontal, 12).padding(.vertical, 8)
    .background(HaloTheme.surface, in: Capsule())
    .background(.ultraThinMaterial, in: Capsule())
    .overlay(Capsule().strokeBorder(HaloTheme.hairline, lineWidth: 0.5))
    .padding(.horizontal, 22)
  }

  private func iconButton(_ system: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: system)
        .font(.system(size: 18, weight: .regular))
        .foregroundStyle(.white.opacity(0.6))
        .frame(width: 36, height: 36)
    }
    .buttonStyle(.plain)
  }

  private func composeButton() -> some View {
    Button(action: onCompose) {
      ZStack {
        Circle()
          .fill(
            RadialGradient(
              colors: [
                MoodPalette.auraColor(selfMood, l: 0.9),
                MoodPalette.auraColor(selfMood, l: 0.55),
              ],
              center: UnitPoint(x: 0.3, y: 0.3),
              startRadius: 0, endRadius: 28
            )
          )
          .shadow(color: MoodPalette.auraRing(selfMood, alpha: 0.6), radius: 12)
        Image(systemName: "plus")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(.white)
      }
      .frame(width: 52, height: 52)
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  ZStack {
    Color.black
    BottomBarView(selfMood: .focused)
  }
  .frame(width: 402, height: 120)
}
