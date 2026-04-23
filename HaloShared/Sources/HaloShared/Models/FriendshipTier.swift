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

  /// Raggio normalizzato [0…1] per la disposizione sull'orbital field.
  /// inner = vicino al centro, nebula = più esterno.
  public var ringRadius: Double {
    switch self {
    case .inner:  return 0.22
    case .close:  return 0.44
    case .orbit:  return 0.68
    case .nebula: return 0.92
    }
  }

  public static func < (lhs: FriendshipTier, rhs: FriendshipTier) -> Bool {
    lhs.rank < rhs.rank
  }
}
