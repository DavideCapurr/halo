import Foundation

public enum Mood: String, Codable, CaseIterable, Sendable {
  case chill, wild, lost, focused, warm, electric, blue, soft

  public var defaultHex: String {
    switch self {
    case .chill:    return "#5CE1E6"
    case .wild:     return "#E84A5F"
    case .lost:     return "#9B9B9B"
    case .focused:  return "#7C5CFF"
    case .warm:     return "#FF8A5C"
    case .electric: return "#F5D142"
    case .blue:     return "#4A6FE8"
    case .soft:     return "#FFB3C1"
    }
  }
}
