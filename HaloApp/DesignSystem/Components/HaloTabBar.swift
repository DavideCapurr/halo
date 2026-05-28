import SwiftUI
import HaloShared

/// SWARM command dock: navigation nodes plus one central Moment action.
struct HaloTabBar: View {
  enum Tab: String, Hashable, CaseIterable {
    case orbit
    case pulse
    case profile

    var label: String {
      switch self {
      case .orbit: return "Orbita"
      case .pulse: return "Pulse"
      case .profile: return "Halo"
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
    .padding(.horizontal, SwarmHalo.s3)
    .padding(.vertical, SwarmHalo.s2)
    .swarmSurface(.rail, in: Capsule())
    .shadow(color: SwarmHalo.absoluteBlack.opacity(0.42), radius: 22, y: 12)
    .padding(.horizontal, 18)
  }

  private func tabSlot(_ tab: Tab) -> some View {
    let isActive = tab == active
    return Button {
      onSelect(tab)
    } label: {
      VStack(spacing: 4) {
        Image(systemName: tab.icon)
          .font(HaloType.system(15, weight: .medium))
        Text(tab.label)
          .font(HaloType.eyebrow(8.5))
          .kerning(1.6)
          .textCase(.uppercase)
      }
      .foregroundStyle(isActive ? activeRole(for: tab).color : SwarmHalo.inkMuted)
      .frame(maxWidth: .infinity)
      .frame(height: 44)
      .background(
        Capsule()
          .fill(isActive ? activeRole(for: tab).fill : .clear)
      )
      .overlay(
        Capsule()
          .strokeBorder(isActive ? activeRole(for: tab).stroke : .clear, lineWidth: SwarmStroke.hairline)
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
          .fill(SwarmActivationRole.attention.color)
          .shadow(color: SwarmActivationRole.attention.glow, radius: 12)
        Image(systemName: "plus")
          .font(HaloType.system(18, weight: .bold))
          .foregroundStyle(SwarmHalo.background)
      }
      .frame(width: 46, height: 46)
      .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Nuovo Moment")
  }

  private func activeRole(for tab: Tab) -> SwarmActivationRole {
    switch tab {
    case .orbit: return .connected
    case .pulse: return .operational
    case .profile: return .rest
    }
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
