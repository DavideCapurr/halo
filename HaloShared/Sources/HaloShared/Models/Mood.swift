import Foundation

/// Mood enum + design palette tokens.
/// Hue (0..360°) e chroma corrispondono al sistema OKLCH definito nel design Halo Orbital Field.
public enum Mood: String, Codable, CaseIterable, Sendable {
  case chill, wild, lost, focused, warm, electric, blue, soft

  public var hue: Double {
    switch self {
    case .chill:    return 240
    case .wild:     return 340
    case .lost:     return 290
    case .focused:  return 200
    case .warm:     return  55
    case .electric: return 170
    case .blue:     return 255
    case .soft:     return  20
    }
  }

  public var chroma: Double {
    switch self {
    case .chill:    return 0.045
    case .wild:     return 0.070
    case .lost:     return 0.050
    case .focused:  return 0.045
    case .warm:     return 0.055
    case .electric: return 0.060
    case .blue:     return 0.040
    case .soft:     return 0.035
    }
  }

  /// Hex precomputato per uso non SwiftUI (es. seed DB, widget snapshot, debug).
  /// Equivalente di `auraColor(mood, l = 0.58)` calcolato offline in sRGB.
  public var defaultHex: String {
    switch self {
    case .chill:    return "#7E8AC2"
    case .wild:     return "#B7647F"
    case .lost:     return "#9874A8"
    case .focused:  return "#6F95B3"
    case .warm:     return "#A99166"
    case .electric: return "#5DA59A"
    case .blue:     return "#7281B5"
    case .soft:     return "#A38478"
    }
  }
}
