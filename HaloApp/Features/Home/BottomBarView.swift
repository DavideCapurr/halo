import SwiftUI
import HaloShared

/// Floating glass command dock. Quattro destinazioni più l'azione centrale.
///
/// I nomi delle tab sono parole comuni, non nomi di schermate: il budget di
/// `docs/PRODOTTO.md` §7 è di **tre** termini proprietari in tutto il first run
/// — Ring, Vibe, Halo — e la vecchia dock ne spendeva quattro nuovi da sola
/// (Orbita, Pulse, Stato, Moment), nessuno dei quali è un concetto che valga la
/// pena insegnare.
///
/// Il Ring è qui perché è la prova di co-presenza, cioè il core (§5). Prima era
/// il quarto item di un pannello dentro il profilo, sotto l'impalcatura campus
/// e le feature congelate.
struct BottomBarView: View {
  enum Tab {
    case halo
    case adesso
    case ring
    case profile
  }

  let selfMood: Mood
  var activeTab: Tab = .halo
  var onCompose: () -> Void = {}
  var onEasy: () -> Void = {}
  var onHalo: () -> Void = {}
  var onAdesso: () -> Void = {}
  var onRing: () -> Void = {}
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
      tabButton(.halo, title: "Halo", icon: "circle.dotted", selectedIcon: "circle.circle.fill", action: onHalo)
      tabButton(.adesso, title: "Adesso", icon: "waveform.path.ecg", selectedIcon: "waveform.path.ecg", action: onAdesso)
      composeButton()
      tabButton(.ring, title: "Ring", icon: "qrcode.viewfinder", selectedIcon: "qrcode.viewfinder", action: onRing)
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
      .accessibilityLabel("Condividi")
      .accessibilityHint("Tocca per scegliere chi vede, tieni premuto per mandarlo ai più vicini")
  }
}

#Preview {
  ZStack {
    SwarmHalo.background
    BottomBarView(selfMood: .focused, activeTab: .adesso)
  }
  .frame(width: 402, height: 120)
}
