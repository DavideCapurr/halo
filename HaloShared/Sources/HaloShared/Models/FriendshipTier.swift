import Foundation

public enum FriendshipTier: String, Codable, CaseIterable, Comparable, Sendable {
  case asteroid, nebula, orbit, close, inner

  public var rank: Int {
    switch self {
    case .asteroid: return 0
    case .nebula:   return 1
    case .orbit:    return 2
    case .close:    return 3
    case .inner:    return 4
    }
  }

  public var softCap: Int? {
    switch self {
    case .inner:    return 5
    case .close:    return 15
    case .orbit:    return 50
    case .nebula:   return nil
    case .asteroid: return nil
    }
  }

  /// Display label for UI copy. Inner / Close stay English as brand-specific
  /// product terms; Orbita / Nebula translate. See `docs/research/vocabulary.md`.
  public var label: String {
    switch self {
    case .inner:    return "Inner"
    case .close:    return "Close"
    case .orbit:    return "Orbita"
    case .nebula:   return "Nebula"
    case .asteroid: return "Asteroidi"
    }
  }

  /// Compact ordinal used in micro-typography (e.g. "n° 01" for inner).
  /// Stable, doesn't change with copy.
  public var ordinal: Int {
    switch self {
    case .inner:    return 1
    case .close:    return 2
    case .orbit:    return 3
    case .nebula:   return 4
    case .asteroid: return 5
    }
  }

  /// Raggio normalizzato come frazione di `maxR` del campo orbitale (design Deep Space).
  /// Inner vicino al centro; nebula si spinge oltre il bordo (1.08) per "pizzicare" lateralmente.
  /// Asteroid è oltre la nebula (1.30): non vive su un anello, viene reso nella cintura.
  public var ringRadius: Double {
    switch self {
    case .inner:    return 0.32
    case .close:    return 0.58
    case .orbit:    return 0.84
    case .nebula:   return 1.08
    case .asteroid: return 1.30
    }
  }

  /// Diametro della bolla (px @ baseline iPhone) per tier.
  /// Iter finale del design: portrait-first, hero al centro, esterni più piccoli.
  /// Asteroid è la bolla più piccola: amici esplicitamente depriorizzati.
  public var bubbleSize: CGFloat {
    switch self {
    case .inner:    return 96
    case .close:    return 72
    case .orbit:    return 52
    case .nebula:   return 38
    case .asteroid: return 28
    }
  }

  /// Offset di fase (gradi) per evitare allineamenti radiali fra anelli.
  /// Asteroid non ha allineamento angolare (drift nella cintura).
  public var anglePhaseDegrees: Double {
    switch self {
    case .inner:    return 18
    case .close:    return 0
    case .orbit:    return 9
    case .nebula:   return 22
    case .asteroid: return 0
    }
  }

  public static func < (lhs: FriendshipTier, rhs: FriendshipTier) -> Bool {
    lhs.rank < rhs.rank
  }
}
