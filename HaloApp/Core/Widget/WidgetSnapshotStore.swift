import Foundation
import WidgetKit
import HaloShared

/// Scrive `WidgetSnapshot` nel container App Group condiviso, per il widget.
/// Chiamare `refresh(from:)` quando cambiano follow / vibe / post: produce uno
/// snapshot dei follow Inner+Close col loro stato attuale (mood, vibe color)
/// e invalida le timeline del widget.
@MainActor
enum WidgetSnapshotStore {
  /// Costruisce uno snapshot a partire da una lista di `MomentItem` (HomeViewModel.feedItems).
  /// Filtra ai soli mutuali Inner+Close, max 12.
  static func buildSnapshot(from items: [MomentItem]) -> WidgetSnapshot {
    let topTier: [MomentItem] = items
      .filter { $0.isMutual && ($0.viewerTier == .inner || $0.viewerTier == .close) }
      .sorted { (a, b) in
        let ar = a.viewerTier?.rank ?? 0
        let br = b.viewerTier?.rank ?? 0
        if ar != br { return ar > br }
        return a.lastActivityAt > b.lastActivityAt
      }
      .prefix(12)
      .map { $0 }

    let bubbles: [WidgetSnapshot.Bubble] = topTier.map { item in
      WidgetSnapshot.Bubble(
        userId: item.profile.id,
        handle: item.profile.handle,
        displayName: item.profile.displayName,
        avatarPath: item.profile.avatarPath,
        mood: item.vibe?.mood,
        colorHex: item.vibe?.colorHex,
        tier: item.viewerTier ?? .nebula
      )
    }
    return WidgetSnapshot(generatedAt: .now, bubbles: bubbles)
  }

  /// Scrive lo snapshot su disco e ricarica le timeline.
  static func write(_ snapshot: WidgetSnapshot) throws {
    guard let url = AppGroup.widgetSnapshotURL else { return }
    let enc = JSONEncoder()
    enc.dateEncodingStrategy = .iso8601
    let data = try enc.encode(snapshot)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try data.write(to: url, options: .atomic)
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// Helper: produci e scrivi in un colpo solo.
  static func refresh(from items: [MomentItem]) throws {
    try write(buildSnapshot(from: items))
  }
}
