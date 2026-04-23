import WidgetKit
import SwiftUI

struct StandByWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "HaloStandBy", provider: HaloProvider()) { entry in
      WidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Halo — StandBy")
    .description("La tua orbita in StandBy.")
    .supportedFamilies([.systemMedium])
  }
}
