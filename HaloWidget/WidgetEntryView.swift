import SwiftUI
import WidgetKit
import HaloShared

struct WidgetEntryView: View {
  let entry: HaloEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .accessoryCircular:
      // Lockscreen — mostra fino a 4 bolle in un mini anello.
      ZStack {
        Circle().strokeBorder(.white.opacity(0.3), lineWidth: 0.6)
        // TODO step 12: layout radiale mini con top 4 Inner bubbles.
        Text("\(entry.snapshot.bubbles.count)")
          .font(.caption2)
          .fontWeight(.bold)
      }
    case .accessoryRectangular:
      HStack(spacing: 4) {
        ForEach(entry.snapshot.bubbles.prefix(4), id: \.self) { b in
          Circle().fill(Color(uiColor: .white)).frame(width: 10, height: 10)
            .overlay(alignment: .bottomTrailing) {
              Text(String(b.handle.prefix(1)))
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.black)
            }
        }
      }
    default:
      // StandBy (systemMedium) — fino a 8.
      ZStack {
        Color.black
        Text("Halo · \(entry.snapshot.bubbles.count) bolle")
          .font(.caption)
          .foregroundStyle(.white)
      }
    }
  }
}
