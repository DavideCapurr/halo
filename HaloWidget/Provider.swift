import WidgetKit
import HaloShared

/// Step 12: TimelineProvider. Legge lo snapshot dal file condiviso via App Group.
struct HaloEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

struct HaloProvider: TimelineProvider {
  func placeholder(in context: Context) -> HaloEntry {
    HaloEntry(date: .now, snapshot: .init(bubbles: []))
  }

  func getSnapshot(in context: Context, completion: @escaping (HaloEntry) -> Void) {
    completion(HaloEntry(date: .now, snapshot: readFromGroup() ?? .init(bubbles: [])))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HaloEntry>) -> Void) {
    let entry = HaloEntry(date: .now, snapshot: readFromGroup() ?? .init(bubbles: []))
    let next = Date().addingTimeInterval(15 * 60)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func readFromGroup() -> WidgetSnapshot? {
    guard let url = AppGroup.widgetSnapshotURL,
          let data = try? Data(contentsOf: url) else { return nil }
    let dec = JSONDecoder()
    dec.dateDecodingStrategy = .iso8601
    return try? dec.decode(WidgetSnapshot.self, from: data)
  }
}
