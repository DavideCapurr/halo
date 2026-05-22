import SwiftUI
import HaloShared

/// Pulse-style tab bar: glass surface, clear labels, one central compose action.
struct HaloTabBar: View {
  enum Tab: String, Hashable, CaseIterable {
    case orbit
    case pulse
    case profile

    var label: String {
      switch self {
      case .orbit: return "Orbita"
      case .pulse: return "Pulse"
      case .profile: return "Tu"
      }
    }

    var icon: String {
      switch self {
      case .orbit: return "circle.grid.cross"
      case .pulse: return "waveform.path.ecg"
      case .profile: return "person.crop.circle"
      }
    }
  }

  let active: Tab
  let selfMood: Mood
  var onSelect: (Tab) -> Void = { _ in }
  var onCompose: () -> Void = {}

  var body: some View {
    HStack(spacing: 8) {
      tabSlot(.orbit)
      tabSlot(.pulse)
      composeSlot
      tabSlot(.profile)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
              LinearGradient(
                colors: [Color.white.opacity(0.04), .clear, Color.black.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
              )
            )
        )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
    )
    .shadow(color: .black.opacity(0.42), radius: 22, y: 12)
    .padding(.horizontal, 18)
  }

  private func tabSlot(_ tab: Tab) -> some View {
    let isActive = tab == active
    return Button {
      onSelect(tab)
    } label: {
      VStack(spacing: 4) {
        Image(systemName: tab.icon)
          .font(.system(size: 15, weight: .medium))
        Text(tab.label)
          .font(HaloType.eyebrow(8.5))
          .kerning(1.6)
          .textCase(.uppercase)
      }
      .foregroundStyle(isActive ? HaloInk.cream : HaloInk.creamMute)
      .frame(maxWidth: .infinity)
      .frame(height: 44)
      .background(
        Capsule()
          .fill(isActive ? HaloInk.creamWhisper : .clear)
      )
      .overlay(
        Capsule()
          .strokeBorder(isActive ? HaloInk.creamLine : .clear, lineWidth: 0.5)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(tab.label)
    .accessibilityAddTraits(isActive ? .isSelected : [])
  }

  private var composeSlot: some View {
    Button(action: onCompose) {
      ZStack {
        Circle()
          .fill(MoodPalette.auraColor(selfMood, l: 0.70))
          .shadow(color: MoodPalette.auraRing(selfMood, alpha: 0.45), radius: 10)
        Image(systemName: "plus")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(.white)
      }
      .frame(width: 46, height: 46)
      .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Pubblica")
  }
}

#Preview {
  ZStack {
    DeepSpaceBackground()
    VStack {
      Spacer()
      HaloTabBar(active: .pulse, selfMood: .warm)
        .padding(.bottom, 28)
    }
  }
  .preferredColorScheme(.dark)
  .ignoresSafeArea()
}
