import SwiftUI
import HaloShared

/// Floating glass command dock. Four destinations plus a central Moment action.
/// Tap the centre to compose a Moment (vibe-first); long-press for the
/// frictionless "easy" share that goes to your Inner and fades in 3 hours.
struct BottomBarView: View {
  enum Tab {
    case orbit
    case pulse
    case stato
    case profile
  }

  let selfMood: Mood
  var activeTab: Tab = .orbit
  var onCompose: () -> Void = {}
  var onEasy: () -> Void = {}
  var onOrbit: () -> Void = {}
  var onPulse: () -> Void = {}
  var onStato: () -> Void = {}
  var onProfile: () -> Void = {}

  var body: some View {
    HStack(spacing: 10) {
      tabButton(.orbit, title: "Orbita", icon: "circle.dotted", selectedIcon: "circle.circle.fill", action: onOrbit)
      tabButton(.pulse, title: "Pulse", icon: "waveform.path.ecg", selectedIcon: "waveform.path.ecg", action: onPulse)
      composeButton()
      tabButton(.stato, title: "Stato", icon: "circle.grid.2x2", selectedIcon: "circle.grid.2x2.fill", action: onStato)
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

    return Button(action: action) {
      VStack(spacing: 3) {
        Image(systemName: isSelected ? selectedIcon : icon)
          .font(HaloType.system(17, weight: isSelected ? .semibold : .regular))
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
            .haloGlass(in: Capsule(), tint: SwarmHalo.bronze.opacity(0.5), interactive: true)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private func composeButton() -> some View {
    ZStack {
      Circle()
        .fill(.clear)
        .haloGlass(in: Circle(), tint: MoodPalette.auraColor(selfMood, l: 0.58), interactive: true)
      Image(systemName: "plus")
        .font(HaloType.system(20, weight: .semibold))
        .foregroundStyle(MoodPalette.onAccent(selfMood, l: 0.58))
    }
    .frame(width: 50, height: 50)
    .shadow(color: MoodPalette.auraRing(selfMood, alpha: 0.26), radius: 10, y: 3)
    .contentShape(Circle())
    .onTapGesture(perform: onCompose)
    .onLongPressGesture(minimumDuration: 0.35, perform: onEasy)
    .accessibilityLabel("Nuovo Moment")
    .accessibilityHint("Tocca per un Moment, tieni premuto per condividere veloce")
  }
}

#Preview {
  ZStack {
    SwarmHalo.background
    BottomBarView(selfMood: .focused, activeTab: .pulse)
  }
  .frame(width: 402, height: 120)
}
