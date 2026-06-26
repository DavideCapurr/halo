import SwiftUI
import HaloShared

/// Pulse-style top bar: readable vibe pill + search affordance.
struct TopBarView: View {
  let mood: Mood
  var onVibeTap: () -> Void = {}
  var onSearchTap: () -> Void = {}

  var body: some View {
    HStack {
      Button(action: onVibeTap) {
        vibePill
      }
      .buttonStyle(.plain)

      Spacer()

      Text(Self.dateString)
        .font(HaloType.mono(9, weight: .medium))
        .kerning(1.5)
        .textCase(.uppercase)
        .foregroundStyle(HaloInk.creamMute)

      Button(action: onSearchTap) {
        searchButtonChrome
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 18)
    .frame(height: 44)
  }

  @ViewBuilder
  private var vibePill: some View {
    let content = HStack(spacing: 8) {
      Circle()
        .fill(MoodPalette.auraColor(mood, l: 0.80))
        .frame(width: 10, height: 10)
        .shadow(color: MoodPalette.auraRing(mood, alpha: 0.5), radius: 5)
      Text("la tua vibe · \(mood.rawValue)")
        .font(HaloType.ui(13, weight: .medium))
        .foregroundStyle(HaloInk.cream)
        .lineLimit(1)
    }
    .padding(.leading, 8)
    .padding(.trailing, 12)
    .padding(.vertical, 7)

    if #available(iOS 26.0, *) {
      content
        .background(HaloVisual.Orbita.chromeFillStrong.opacity(0.72), in: Capsule())
        .glassEffect(.regular.tint(HaloVisual.Orbita.chromeFillStrong.opacity(0.72)).interactive(), in: Capsule())
        .overlay(Capsule().strokeBorder(HaloVisual.Orbita.chromeStroke, lineWidth: 0.8))
    } else {
      content
        .background(HaloVisual.Orbita.chromeFillStrong, in: Capsule())
        .overlay(Capsule().strokeBorder(HaloVisual.Orbita.chromeStroke, lineWidth: 0.8))
    }
  }

  @ViewBuilder
  private var searchButtonChrome: some View {
    let content = Image(systemName: "magnifyingglass")
      .font(HaloType.system(15, weight: .regular))
      .foregroundStyle(HaloInk.creamLow)
      .frame(width: 36, height: 36)

    if #available(iOS 26.0, *) {
      content
        .background(HaloVisual.Orbita.chromeFillStrong.opacity(0.72), in: Circle())
        .glassEffect(.regular.tint(HaloVisual.Orbita.chromeFillStrong.opacity(0.72)).interactive(), in: Circle())
        .overlay(Circle().strokeBorder(HaloVisual.Orbita.chromeStroke, lineWidth: 0.8))
    } else {
      content
        .background(HaloVisual.Orbita.chromeFillStrong, in: Circle())
        .overlay(Circle().strokeBorder(HaloVisual.Orbita.chromeStroke, lineWidth: 0.8))
    }
  }

  private static var dateString: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "it_IT")
    formatter.setLocalizedDateFormatFromTemplate("EEE d")
    return formatter.string(from: .now).replacingOccurrences(of: ".", with: "")
  }
}

#Preview {
  ZStack {
    SwarmHalo.background
    TopBarView(mood: .chill)
  }
  .frame(width: 402, height: 100)
}
