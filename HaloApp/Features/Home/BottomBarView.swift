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

  @ViewBuilder
  var body: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: 10) {
        dockContent
          .background(HaloVisual.Orbita.chromeFillStrong.opacity(0.72), in: Capsule())
          .glassEffect(.regular.tint(HaloVisual.Orbita.chromeFillStrong.opacity(0.72)).interactive(), in: Capsule())
          .overlay(Capsule().strokeBorder(HaloVisual.Orbita.dockStroke, lineWidth: 0.9))
          .shadow(color: HaloVisual.Orbita.dockShadow, radius: 22, y: 12)
      }
      .padding(.horizontal, HaloVisual.Orbita.dockHorizontalPadding)
    } else {
      dockContent
        .background(HaloVisual.Orbita.chromeFillStrong, in: Capsule())
        .overlay(Capsule().strokeBorder(HaloVisual.Orbita.dockStroke, lineWidth: 0.9))
        .shadow(color: HaloVisual.Orbita.dockShadow, radius: 22, y: 12)
        .padding(.horizontal, HaloVisual.Orbita.dockHorizontalPadding)
    }
  }

  private var dockContent: some View {
    HStack(spacing: 10) {
      tabButton(.orbit, title: "Orbita", icon: "circle.dotted", selectedIcon: "circle.circle.fill", action: onOrbit)
      tabButton(.pulse, title: "Pulse", icon: "waveform.path.ecg", selectedIcon: "waveform.path.ecg", action: onPulse)
      composeButton()
      tabButton(.stato, title: "Stato", icon: "circle.grid.2x2", selectedIcon: "circle.grid.2x2.fill", action: onStato)
      tabButton(.profile, title: "Tu", icon: "person.circle", selectedIcon: "person.circle.fill", action: onProfile)
    }
    .padding(.horizontal, HaloVisual.Orbita.dockInnerHorizontalPadding)
    .padding(.vertical, HaloVisual.Orbita.dockVerticalPadding)
    .frame(maxWidth: .infinity)
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
      .frame(height: HaloVisual.Orbita.dockTabHeight)
      .contentShape(Rectangle())
      .background {
        if isSelected {
          selectedTabBackground
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  @ViewBuilder
  private var selectedTabBackground: some View {
    let shape = RoundedRectangle(cornerRadius: HaloVisual.Orbita.dockSelectedRadius, style: .continuous)
    if #available(iOS 26.0, *) {
      shape
        .fill(HaloVisual.Orbita.selectedFill)
        .glassEffect(.regular.tint(HaloVisual.Orbita.selectedFill).interactive(), in: shape)
        .overlay(shape.strokeBorder(HaloVisual.Orbita.selectedStroke, lineWidth: 0.8))
    } else {
      shape
        .fill(HaloVisual.Orbita.selectedFill)
        .overlay(shape.strokeBorder(HaloVisual.Orbita.selectedStroke, lineWidth: 0.8))
    }
  }

  @ViewBuilder
  private func composeButton() -> some View {
    let accent = MoodPalette.auraColor(selfMood, l: 0.78)

    ZStack {
      if #available(iOS 26.0, *) {
        Circle()
          .fill(HaloVisual.Orbita.chromeFillStrong.opacity(0.60))
          .glassEffect(.regular.tint(accent.opacity(0.24)).interactive(), in: Circle())
          .overlay(Circle().strokeBorder(accent.opacity(0.84), lineWidth: 1.1))
      } else {
        Circle()
          .fill(HaloVisual.Orbita.chromeFillStrong)
          .overlay(Circle().strokeBorder(accent.opacity(0.84), lineWidth: 1.1))
      }

      Image(systemName: "plus")
        .font(HaloType.system(20, weight: .semibold))
        .foregroundStyle(accent)
    }
      .frame(width: HaloVisual.Orbita.dockComposeSize, height: HaloVisual.Orbita.dockComposeSize)
      .shadow(color: MoodPalette.auraRing(selfMood, alpha: 0.30), radius: 12, y: 4)
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
