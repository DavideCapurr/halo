import WidgetKit
import SwiftUI

struct LockscreenWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "HaloLockscreen", provider: HaloProvider()) { entry in
      WidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Halo — Bolle")
    .description("Come stanno le persone che hai incontrato.")
    .supportedFamilies([.accessoryCircular, .accessoryRectangular])
  }
}
