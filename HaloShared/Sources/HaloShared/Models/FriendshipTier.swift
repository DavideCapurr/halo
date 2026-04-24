import Foundation

public enum FriendshipTier: String, Codable, CaseIterable, Comparable, Sendable {
  case nebula, orbit, close, inner

  public var rank: Int {
    switch self {
    case .nebula: return 1
    case .orbit:  return 2
    case .close:  return 3
    case .inner:  return 4
    }
  }

  public var softCap: Int? {
    switch self {
    case .inner:  return 5
    case .close:  return 15
    case .orbit:  return 50
    case .nebula: return nil
    }
  }

  /// Italian label as used in copy.
  public var label: String {
    switch self {
    case .inner:  return "Inner"
    case .close:  return "Close"
    case .orbit:  return "Orbit"
    case .nebula: return "Nebula"
    }
  }

  /// Raggio normalizzato come frazione di `maxR` del campo orbitale (design Deep Space).
  /// Inner vicino al centro; nebula si spinge oltre il bordo (1.08) per "pizzicare" lateralmente.
  public var ringRadius: Double {
    switch self {
    case .inner:  return 0.32
    case .close:  return 0.58
    case .orbit:  return 0.84
    case .nebula: return 1.08
    }
  }

  /// Diametro della bolla (px @ baseline iPhone) per tier.
  /// Iter finale del design: portrait-first, hero al centro, esterni più piccoli.
  public var bubbleSize: CGFloat {
    switch self {
    case .inner:  return 96
    case .close:  return 72
    case .orbit:  return 52
    case .nebula: return 38
    }
  }

  /// Offset di fase (gradi) per evitare allineamenti radiali fra anelli.
  public var anglePhaseDegrees: Double {
    switch self {
    case .inner:  return 18
    case .close:  return 0
    case .orbit:  return 9
    case .nebula: return 22
    }
  }

  public static func < (lhs: FriendshipTier, rhs: FriendshipTier) -> Bool {
    lhs.rank < rhs.rank
  }
}
