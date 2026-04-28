import Foundation

/// Dynamic copy for time-of-day. Headers like *"Stanotte"* must reflect the
/// real local hour rather than being hardcoded — this enum picks the right
/// italian noun for every moment of the day.
enum HaloMoment {
  case notte       // 23:00 – 04:59
  case alba        // 05:00 – 06:59
  case mattina     // 07:00 – 11:59
  case pomeriggio  // 12:00 – 17:59
  case sera        // 18:00 – 22:59

  /// Pick from the user's current local hour.
  static func current(now: Date = .now, calendar: Calendar = .current) -> HaloMoment {
    let h = calendar.component(.hour, from: now)
    switch h {
    case 5..<7:   return .alba
    case 7..<12:  return .mattina
    case 12..<18: return .pomeriggio
    case 18..<23: return .sera
    default:      return .notte
    }
  }

  /// Editorial headline — italic serif noun (e.g. "Stanotte.").
  /// Used as the big H1 on the Pulse view and similar surfaces.
  var headline: String {
    switch self {
    case .notte:      return "Stanotte"
    case .alba:       return "All'alba"
    case .mattina:    return "Stamattina"
    case .pomeriggio: return "Oggi"
    case .sera:       return "Stasera"
    }
  }

  /// Tiny eyebrow above the headline ("ore 02:14" style).
  var eyebrow: String {
    switch self {
    case .notte:      return "le ore piccole"
    case .alba:       return "primissima luce"
    case .mattina:    return "in mattinata"
    case .pomeriggio: return "nel pomeriggio"
    case .sera:       return "in serata"
    }
  }

  /// Subtitle — short evocative half-sentence shown under the headline.
  var subtitle: String {
    switch self {
    case .notte:      return "chi è ancora sveglio."
    case .alba:       return "i primi a respirare."
    case .mattina:    return "chi ha già iniziato."
    case .pomeriggio: return "chi è in giro adesso."
    case .sera:       return "chi sta scendendo."
    }
  }
}
