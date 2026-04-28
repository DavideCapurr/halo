import SwiftUI
import HaloShared

/// Bottom strip editoriale: una hairline, tre comandi tipografici e un solo
/// accento bronzo. Niente capsule glass: più 2016, meno giocattolo.
struct HaloTabBar: View {
  enum Tab: String, Hashable, CaseIterable {
    case orbit
    case pulse
    case profile

    var label: String {
      switch self {
      case .orbit:   return "Orbita"
      case .pulse:   return "Pulse"
      case .profile: return "Tu"
      }
    }
  }

  let active: Tab
  let selfMood: Mood
  var onSelect: (Tab) -> Void = { _ in }
  var onCompose: () -> Void = {}

  var body: some View {
    VStack(spacing: 14) {
      Rectangle()
        .fill(HaloInk.creamLine)
        .frame(height: 0.5)

      HStack(alignment: .center, spacing: 0) {
        tabSlot(.orbit)
        tabSlot(.pulse)
        composeSlot
        tabSlot(.profile)
      }
    }
    .padding(.horizontal, 22)
    .padding(.top, 2)
    .padding(.bottom, 4)
    .background(
      LinearGradient(
        colors: [.clear, HaloInk.nightSurface.opacity(0.72), HaloInk.nightSurface.opacity(0.92)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea(edges: .bottom)
    )
  }

  // MARK: - tab slot

  private func tabSlot(_ tab: Tab) -> some View {
    let isActive = tab == active
    return Button {
      onSelect(tab)
    } label: {
      HStack(spacing: 4) {
        if isActive {
          Text("·")
            .foregroundStyle(HaloInk.bronze)
        }
        Text(tab.label)
      }
      .font(HaloType.mono(9.5, weight: .medium))
      .kerning(2.0)
      .textCase(.uppercase)
      .foregroundStyle(isActive ? HaloInk.cream : HaloInk.creamMute)
      .frame(maxWidth: .infinity)
      .frame(height: 30)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(tab.label)
    .accessibilityAddTraits(isActive ? .isSelected : [])
  }

  // MARK: - centered compose ("halo crest" button)

  private var composeSlot: some View {
    Button(action: onCompose) {
      HStack(spacing: 5) {
        Circle()
          .strokeBorder(HaloInk.cream, lineWidth: 1.0)
          .frame(width: 12, height: 12)
        Text("manda")
      }
      .font(HaloType.mono(9.5, weight: .medium))
      .kerning(2.0)
      .textCase(.uppercase)
      .foregroundStyle(HaloInk.cream)
      .frame(maxWidth: .infinity)
      .frame(height: 30)
      .contentShape(Rectangle())
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
