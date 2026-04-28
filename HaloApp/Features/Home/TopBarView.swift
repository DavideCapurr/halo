import SwiftUI
import HaloShared

/// TopBar v2: wordmark + data, con vibe ridotta a micro-segnale.
struct TopBarView: View {
  let mood: Mood
  var onVibeTap: () -> Void = {}
  var onSearchTap: () -> Void = {}

  var body: some View {
    HStack {
      Button(action: onVibeTap) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          HaloWordmark()
          Circle()
            .fill(MoodPalette.auraColor(mood, l: 0.72))
            .frame(width: 5, height: 5)
            .offset(y: -1)
        }
        .frame(height: 38)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Spacer()

      Text(Self.dateString)
        .font(HaloType.mono(10, weight: .medium))
        .kerning(1.2)
        .textCase(.uppercase)
        .foregroundStyle(HaloInk.creamMute)

      Button(action: onSearchTap) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(HaloInk.creamLow)
          .frame(width: 36, height: 36)
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 22)
    .frame(height: 38)
  }

  private static var dateString: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "it_IT")
    formatter.setLocalizedDateFormatFromTemplate("EEE d")
    return formatter.string(from: .now).replacingOccurrences(of: ".", with: "")
  }
}

private struct HaloWordmark: View {
  var body: some View {
    HStack(alignment: .top, spacing: 4) {
      Text("HALO")
        .font(HaloType.ui(11, weight: .medium))
        .kerning(4.2)
        .foregroundStyle(HaloInk.cream)
        .overlay(alignment: .topLeading) {
          Circle()
            .strokeBorder(HaloInk.cream, lineWidth: 0.8)
            .frame(width: 8, height: 8)
            .offset(x: 1, y: -8)
        }
    }
    .padding(.top, 7)
  }
}

#Preview {
  ZStack {
    Color.black
    TopBarView(mood: .chill)
  }
  .frame(width: 402, height: 100)
}
