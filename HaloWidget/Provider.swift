import WidgetKit
import HaloShared

/// TimelineProvider del widget Halo.
/// Legge `WidgetSnapshot` dal container App Group; se assente, ritorna snapshot vuoto.
struct HaloEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

struct HaloProvider: TimelineProvider {
  func placeholder(in context: Context) -> HaloEntry {
    HaloEntry(date: .now, snapshot: WidgetSnapshot(bubbles: []))
  }

  func getSnapshot(in context: Context, completion: @escaping (HaloEntry) -> Void) {
    completion(HaloEntry(date: .now, snapshot: readFromGroup() ?? WidgetSnapshot(bubbles: [])))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HaloEntry>) -> Void) {
    let snapshot = readFromGroup() ?? WidgetSnapshot(bubbles: [])
    let entry = HaloEntry(date: .now, snapshot: snapshot)
    // Refresh ogni 15 min; l'app forza un reload via WidgetCenter quando serve.
    let next = Date().addingTimeInterval(15 * 60)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func readFromGroup() -> WidgetSnapshot? {
    guard let url = AppGroup.widgetSnapshotURL,
          FileManager.default.fileExists(atPath: url.path),
          let data = try? Data(contentsOf: url) else {
      return nil
    }
    let dec = JSONDecoder()
    dec.dateDecodingStrategy = .iso8601
    return try? dec.decode(WidgetSnapshot.self, from: data)
  }
}
