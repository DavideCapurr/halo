import Foundation
import CoreGraphics
import HaloShared

/// Livelli di zoom dell'orbital field.
/// `innerOnly`: solo Inner, hero gigante. `innerClose`: Inner + Close visibili.
/// `full`: tutti e 4 gli anelli (default). `asteroids`: zoom out, mostra la cintura.
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
    case (.inner,  .innerOnly):  return 0.70
    case (.close,  .innerOnly):  return 1.45
    case (.orbit,  .innerOnly):  return 1.85
    case (.nebula, .innerOnly):  return 2.20

    case (.inner,  .innerClose): return 0.42
    case (.close,  .innerClose): return 0.86
    case (.orbit,  .innerClose): return 1.40
    case (.nebula, .innerClose): return 1.80

    case (.inner,  .full):       return 0.32
    case (.close,  .full):       return 0.58
    case (.orbit,  .full):       return 0.84
    case (.nebula, .full):       return 1.08

    case (.inner,  .asteroids):  return 0.20
    case (.close,  .asteroids):  return 0.36
    case (.orbit,  .asteroids):  return 0.52
    case (.nebula, .asteroids):  return 0.70
    }
  }

  /// Diametro bolla (px) per il livello di zoom.
  /// `Inner` cresce di più degli altri tier in zoom-in (hero focus).
  func bubbleSize(at zoom: ZoomLevel) -> CGFloat {
    let baseScale: CGFloat
    switch zoom {
    case .innerOnly:  baseScale = 1.55
    case .innerClose: baseScale = 1.22
    case .full:       baseScale = 1.00
    case .asteroids:  baseScale = 0.68
    }
    let innerBoost: CGFloat = {
      guard self == .inner else { return 1.0 }
      switch zoom {
      case .innerOnly:  return 1.30
      case .innerClose: return 1.10
      case .full:       return 1.00
      case .asteroids:  return 0.95
      }
    }()
    return self.bubbleSize * baseScale * innerBoost
  }

  /// Vero se il ring è dentro al viewport (renderizzabile) per il dato zoom.
  func isVisible(at zoom: ZoomLevel) -> Bool {
    self.ringRadius(at: zoom) <= 1.20
  }
}
