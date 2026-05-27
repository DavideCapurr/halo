import SwiftUI
import HaloShared

/// Bottom tab bar ispirata al layer di navigazione di iOS 26:
/// floating glass, tab attiva leggibile, compose centrale prominente.
struct BottomBarView: View {
  enum Tab {
    case orbit
    case feed
    case pulse
    case profile
  }

  let selfMood: Mood
  var activeTab: Tab = .orbit
  var onCompose: () -> Void = {}
  var onOrbit: () -> Void = {}
  var onFeed: () -> Void = {}
  var onPulse: () -> Void = {}
  var onProfile: () -> Void = {}

  var body: some View {
    HStack(spacing: 10) {
      tabButton(.orbit, title: "Orbita", icon: "circle.dotted", selectedIcon: "circle.dotted.circle.fill", action: onOrbit)
      tabButton(.feed, title: "Feed", icon: "text.alignleft", selectedIcon: "text.alignleft", action: onFeed)
      composeButton()
      tabButton(.pulse, title: "Pulse", icon: "list.dash", selectedIcon: "list.bullet.rectangle.fill", action: onPulse)
      tabButton(.profile, title: "Tu", icon: "person.circle", selectedIcon: "person.circle.fill", action: onProfile)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity)
    .haloGlass(in: Capsule(), interactive: true)
    .padding(.horizontal, 18)
  }

  private func tabButton(
    _ tab: Tab,
    title: String,
    icon: String,
    selectedIcon: String,
    action: @escaping () -> Void
  ) -> some View {
    let isSelected = activeTab == tab
    let tint = tabTint(for: tab)

    return Button(action: action) {
      VStack(spacing: 3) {
        Image(systemName: isSelected ? selectedIcon : icon)
          .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
        Text(title)
          .font(HaloType.eyebrow(9))
          .kerning(1.6)
          .textCase(.uppercase)
          .lineLimit(1)
      }
      .foregroundStyle(isSelected ? HaloInk.cream : HaloInk.creamMute)
      .frame(maxWidth: .infinity)
      .frame(height: 44)
      .contentShape(Rectangle())
      .background {
        if isSelected {
          Capsule()
            .fill(.clear)
            .haloGlass(in: Capsule(), tint: tint, interactive: true)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
  }

  private func composeButton() -> some View {
    Button(action: onCompose) {
      ZStack {
        Circle()
          .fill(.clear)
          .haloGlass(in: Circle(), tint: MoodPalette.auraColor(selfMood, l: 0.58), interactive: true)
        Image(systemName: "plus")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(SwarmHalo.background)
      }
      .frame(width: 50, height: 50)
      .shadow(color: MoodPalette.auraRing(selfMood, alpha: 0.26), radius: 10, y: 3)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Compose")
  }

  private func tabTint(for tab: Tab) -> Color {
    switch tab {
    case .orbit:   return MoodPalette.auraColor(selfMood, l: 0.48)
    case .feed:    return SwarmHalo.inkHairline
    case .pulse:   return MoodPalette.auraColor(.electric, l: 0.55)
    case .profile: return MoodPalette.auraColor(.soft, l: 0.58)
    }
  }
}

#Preview {
  ZStack {
    SwarmHalo.background
    BottomBarView(selfMood: .focused, activeTab: .pulse)
  }
  .frame(width: 402, height: 120)
}
