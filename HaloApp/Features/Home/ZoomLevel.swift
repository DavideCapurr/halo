import Foundation

/// Livelli di zoom del campo orbitale.
/// `innerOnly`: solo Inner, hero gigante. `innerClose`: Inner + Close visibili.
/// `full`: Inner + Close + Orbit (default). `asteroids`: zoom out, mostra la cintura.
enum ZoomLevel: Int, CaseIterable, Sendable {
  case innerOnly  = 0
  case innerClose = 1
  case full       = 2
  case asteroids  = 3

  /// Step in/out: pinch out → zoomIn (più ravvicinato), pinch in → zoomOut.
  func zoomedIn() -> ZoomLevel {
    ZoomLevel(rawValue: max(rawValue - 1, ZoomLevel.innerOnly.rawValue)) ?? .innerOnly
  }
  func zoomedOut() -> ZoomLevel {
    ZoomLevel(rawValue: min(rawValue + 1, ZoomLevel.asteroids.rawValue)) ?? .asteroids
  }
}
