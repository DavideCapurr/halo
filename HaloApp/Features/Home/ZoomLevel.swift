import Foundation
import CoreGraphics
import HaloShared

/// Livelli di zoom dell'orbital field.
/// `innerOnly`: solo Inner, hero gigante. `innerClose`: Inner + Close visibili.
/// `full`: Inner + Close + Orbit (default). `asteroids`: zoom out, mostra Nebula e cintura.
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

  /// Raggio "fattore di pan" usato dall'AsteroidBeltView (oltre Nebula).
  var asteroidsVisible: Bool { self == .asteroids }
}

extension FriendshipTier {
  /// Raggio normalizzato del ring del tier per il livello di zoom.
  /// >= 1.2 = fuori viewport (non renderizzato).
  func ringRadius(at zoom: ZoomLevel) -> Double {
    switch (self, zoom) {
    case (.inner,  .innerOnly):  return 0.68
    case (.close,  .innerOnly):  return 1.45
    case (.orbit,  .innerOnly):  return 1.85
    case (.nebula, .innerOnly):  return 2.20

    case (.inner,  .innerClose): return 0.40
    case (.close,  .innerClose): return 0.82
    case (.orbit,  .innerClose): return 1.40
    case (.nebula, .innerClose): return 1.80

    case (.inner,  .full):       return 0.30
    case (.close,  .full):       return 0.56
    case (.orbit,  .full):       return 0.90
    case (.nebula, .full):       return 1.32

    case (.inner,  .asteroids):  return 0.20
    case (.close,  .asteroids):  return 0.36
    case (.orbit,  .asteroids):  return 0.54
    case (.nebula, .asteroids):  return 0.78
    }
  }

  /// Diametro bolla (px) per il livello di zoom.
  /// `Inner` cresce di più degli altri tier in zoom-in (hero focus).
  func bubbleSize(at zoom: ZoomLevel) -> CGFloat {
    switch zoom {
    case .innerOnly:
      switch self {
      case .inner:  return self.bubbleSize * 2.05
      case .close:  return self.bubbleSize * 1.45
      case .orbit:  return self.bubbleSize * 1.35
      case .nebula: return self.bubbleSize * 1.25
      }
    case .innerClose:
      switch self {
      case .inner:  return self.bubbleSize * 1.55
      case .close:  return self.bubbleSize * 1.35
      case .orbit:  return self.bubbleSize * 1.25
      case .nebula: return self.bubbleSize * 1.18
      }
    case .full:
      switch self {
      case .inner:  return self.bubbleSize * 1.08
      case .close:  return self.bubbleSize * 1.16
      case .orbit:  return self.bubbleSize * 1.32
      case .nebula: return self.bubbleSize * 1.24
      }
    case .asteroids:
      switch self {
      case .inner:  return self.bubbleSize * 0.78
      case .close:  return self.bubbleSize * 0.86
      case .orbit:  return self.bubbleSize * 0.98
      case .nebula: return self.bubbleSize * 1.24
      }
    }
  }

  /// Vero se il ring è dentro al viewport (renderizzabile) per il dato zoom.
  func isVisible(at zoom: ZoomLevel) -> Bool {
    self.ringRadius(at: zoom) <= 1.20
  }
}
