import SwiftUI
import HaloShared

/// Halo v2 floating glass tab bar.
///
/// Replaces the iOS-default `TabView` chrome with a single glass capsule
/// that floats above the content. Three primary tabs + a centered compose
/// "halo" button that always carries the user's current vibe colour.
///
/// Visual language:
///  - hairline glass capsule with soft inner shadow
///  - inactive tab = mono small-caps label (no icon-glyph to avoid noise)
///  - active tab = italic serif label + bronze underline dot
///  - compose = centered crest button (the halo ring) tinted with vibe
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
    HStack(spacing: 0) {
      tabSlot(.orbit)
      tabSlot(.pulse)
      composeSlot
      tabSlot(.profile)
      // We don't need a 5th slot — the compose lives in the third position
      // so the bar reads: orbit · pulse · ◯ · tu (three labels + crest).
      Color.clear.frame(width: 0)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity)
    .background(barBackground)
    .overlay(
      Capsule()
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
    )
    .shadow(color: Color.black.opacity(0.55), radius: 24, y: 14)
    .shadow(color: HaloInk.bronzeGlow, radius: 12, y: 0)
    .padding(.horizontal, 22)
  }

  // MARK: - background (layered glass)

  private var barBackground: some View {
    ZStack {
      // Warm-tinted near-black backstop so the glass reads on any backdrop.
      Capsule().fill(HaloInk.nightSurface.opacity(0.55))
      // Real material blur — what makes it feel like glass.
      Capsule().fill(.ultraThinMaterial)
      // Inner shimmer — top highlight, bottom darkening, to catch the eye.
      Capsule()
        .fill(
          LinearGradient(
            colors: [
              Color.white.opacity(0.05),
              Color.clear,
              Color.black.opacity(0.18),
            ],
            startPoint: .top, endPoint: .bottom
          )
        )
    }
  }

  // MARK: - tab slot

  private func tabSlot(_ tab: Tab) -> some View {
    let isActive = tab == active
    return Button {
      onSelect(tab)
    } label: {
      VStack(spacing: 5) {
        if isActive {
          Text(tab.label.lowercased())
            .font(HaloType.serif(15))
            .foregroundStyle(HaloInk.cream)
            .kerning(-0.2)
        } else {
          Text(tab.label)
            .haloEyebrow(HaloInk.creamMute, size: 9, tracking: 2.4)
        }

        // 4px bronze dot — only on active tab.
        Circle()
          .fill(isActive ? HaloInk.bronze : Color.clear)
          .frame(width: 4, height: 4)
          .shadow(color: HaloInk.bronzeGlow, radius: isActive ? 4 : 0)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 36)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(tab.label)
    .accessibilityAddTraits(isActive ? .isSelected : [])
  }

  // MARK: - centered compose ("halo crest" button)

  private var composeSlot: some View {
    Button(action: onCompose) {
      ZStack {
        // Halo of vibe colour behind the crest — soft glow.
        Circle()
          .fill(MoodPalette.auraColor(selfMood, l: 0.55))
          .frame(width: 38, height: 38)
          .blur(radius: 10)
          .opacity(0.55)

        // Glass disc.
        Circle()
          .fill(.ultraThinMaterial)
          .overlay(
            Circle().strokeBorder(HaloInk.cream.opacity(0.35), lineWidth: 0.8)
          )
          .frame(width: 36, height: 36)

        // Centered crest = a thin ring (the "halo" itself).
        Circle()
          .strokeBorder(HaloInk.cream, lineWidth: 1.1)
          .frame(width: 16, height: 16)

        // Tiny bronze tick to signal "tap → publish".
        Circle()
          .fill(HaloInk.bronze)
          .frame(width: 4, height: 4)
          .offset(x: 12, y: -10)
      }
      .frame(width: 56, height: 56)
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
