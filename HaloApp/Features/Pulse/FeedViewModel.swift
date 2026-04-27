import Foundation
import Observation
import HaloShared

/// View model del Pulse feed.
///
/// In demo mode (`bootstrap = .seed`) costruisce le sezioni a partire da
/// `SeedPeople`. Quando il backend sarà cablato, `bootstrap = .live` userà
/// `PostsService.feedPosts()` + `VibesService.currentVibes()` per produrre
/// `[MomentItem]` reali (vedi `HomeViewModel.feedItems`).
@Observable
@MainActor
final class FeedViewModel {
  enum Bootstrap { case seed, live }

  /// Header visivo del feed: raggruppiamo Inner+Close, Orbit, Nebula.
  enum FeedSection: String, CaseIterable, Hashable {
    case innerClose
    case orbit
    case nebula

    var title: String {
      switch self {
      case .innerClose: return "Inner & Close"
      case .orbit:      return "Orbit"
      case .nebula:     return "Nebula"
      }
    }

    static func from(tier: FriendshipTier) -> FeedSection {
      switch tier {
      case .inner, .close: return .innerClose
      case .orbit:         return .orbit
      case .nebula:        return .nebula
      }
    }
  }

  // Stato di base
  private let bootstrap: Bootstrap
  var people: [DemoPerson] = []
  var isLoading: Bool = false
  var lastError: String?

  init(bootstrap: Bootstrap = .seed) {
    self.bootstrap = bootstrap
  }

  // MARK: - load

  func load() async {
    isLoading = true
    defer { isLoading = false }
    switch bootstrap {
    case .seed:
      // Mutuali in feed; gli asteroidi non finiscono nelle sezioni Inner/Close/Orbit/Nebula.
      self.people = SeedPeople.all
    case .live:
      // TODO: cablato a PostsService/VibesService quando Auth è pronta.
      self.people = SeedPeople.all
    }
  }

  // MARK: - derivate

  /// Persone con post negli ultimi 30 min (sezione "Adesso").
  /// Ordinate per ultimo post desc.
  var adessoItems: [DemoPerson] {
    people
      .filter { p in
        guard let t = p.lastPostAt else { return false }
        return Date.now.timeIntervalSince(t) <= 30 * 60
      }
      .sorted { (a, b) in (a.lastPostAt ?? .distantPast) > (b.lastPostAt ?? .distantPast) }
  }

  /// Persone con vibe attiva, tier-sorted (Inner prima).
  /// Alimenta la `PresenceBar` in cima al feed.
  var presenceItems: [DemoPerson] {
    people
      .filter(\.hasActiveVibe)
      .sorted { (a, b) in
        if a.tier.rank != b.tier.rank { return a.tier.rank > b.tier.rank }
        return (a.lastPostAt ?? .distantPast) > (b.lastPostAt ?? .distantPast)
      }
  }

  /// Sezioni del feed (Inner&Close / Orbit / Nebula), ognuna ordinata per
  /// "ultima attività" desc (= ultimo post; fallback su vibe attiva).
  var sections: [(FeedSection, [DemoPerson])] {
    let grouped = Dictionary(grouping: people, by: { FeedSection.from(tier: $0.tier) })
    return FeedSection.allCases.compactMap { section in
      guard let items = grouped[section], !items.isEmpty else { return nil }
      let sorted = items.sorted { (a, b) in
        let ta = a.lastPostAt ?? (a.hasActiveVibe ? Date.now.addingTimeInterval(-3600) : .distantPast)
        let tb = b.lastPostAt ?? (b.hasActiveVibe ? Date.now.addingTimeInterval(-3600) : .distantPast)
        return ta > tb
      }
      return (section, sorted)
    }
  }

  /// Mood dominante delle prime card visibili (per la tinta del background).
  /// nil se nessuna persona ha una vibe attiva tra le prime N.
  func dominantMood(visibleLimit: Int = 6) -> Mood? {
    let head = people.filter(\.hasActiveVibe).prefix(visibleLimit)
    guard !head.isEmpty else { return nil }
    let counts = Dictionary(head.map { ($0.mood, 1) }, uniquingKeysWith: +)
    return counts.max(by: { $0.value < $1.value })?.key
  }
}
