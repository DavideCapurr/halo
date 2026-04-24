import SwiftUI
import HaloShared

/// TopBar: pill "la tua vibe · <mood>" + bottone search.
struct TopBarView: View {
  let mood: Mood
  var onVibeTap: () -> Void = {}
  var onSearchTap: () -> Void = {}

  var body: some View {
    HStack {
      Button(action: onVibeTap) {
        HStack(spacing: 8) {
          Circle()
            .fill(MoodPalette.auraColor(mood, l: 0.8))
            .frame(width: 10, height: 10)
            .shadow(color: MoodPalette.auraRing(mood, alpha: 0.5), radius: 5)
          Text("la tua vibe · \(mood.rawValue)")
            .font(.system(size: 13, weight: .medium))
            .kerning(-0.1)
            .foregroundStyle(.white.opacity(0.95))
        }
        .padding(.leading, 8).padding(.trailing, 12).padding(.vertical, 7)
        .background(.white.opacity(0.04), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(HaloTheme.hairline, lineWidth: 0.5))
      }
      .buttonStyle(.plain)

      Spacer()

      Button(action: onSearchTap) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 15, weight: .regular))
          .foregroundStyle(.white.opacity(0.75))
          .frame(width: 36, height: 36)
          .background(.white.opacity(0.04), in: Circle())
          .background(.ultraThinMaterial, in: Circle())
          .overlay(Circle().strokeBorder(HaloTheme.hairline, lineWidth: 0.5))
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 18)
    .frame(height: 44)
  }
}

#Preview {
  ZStack {
    Color.black
    TopBarView(mood: .chill)
  }
  .frame(width: 402, height: 100)
}
