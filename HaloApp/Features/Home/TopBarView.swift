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
        HStack(spacing: 8) {
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
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(HaloInk.creamHair, lineWidth: 0.6))
      }
      .buttonStyle(.plain)

      Spacer()

      Text(Self.dateString)
        .font(HaloType.mono(9, weight: .medium))
        .kerning(1.5)
        .textCase(.uppercase)
        .foregroundStyle(HaloInk.creamMute)

      Button(action: onSearchTap) {
        Image(systemName: "magnifyingglass")
          .font(HaloType.system(15, weight: .regular))
          .foregroundStyle(HaloInk.creamLow)
          .frame(width: 36, height: 36)
          .background(Circle().fill(.ultraThinMaterial))
          .overlay(Circle().strokeBorder(HaloInk.creamHair, lineWidth: 0.6))
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 18)
    .frame(height: 44)
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
