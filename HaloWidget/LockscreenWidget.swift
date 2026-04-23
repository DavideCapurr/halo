import WidgetKit
import SwiftUI

struct LockscreenWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "HaloLockscreen", provider: HaloProvider()) { entry in
      WidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Halo — Bolle")
    .description("Le bolle Inner + Close con la vibe di ognuno.")
    .supportedFamilies([.accessoryCircular, .accessoryRectangular])
  }
}
