import Foundation
import Observation
import HaloShared

enum PulseScope: String, CaseIterable, Hashable, Identifiable {
  case cerchio
  case tutti

  var id: String { rawValue }

  var title: String {
    switch self {
    case .cerchio: return "Cerchio"
    case .tutti: return "Tutti"
    }
  }

  var subtitle: String {
    switch self {
    case .cerchio: return "solo persone vicinissime"
    case .tutti: return "tutte le tue orbite"
    }
  }

  var visibleTiers: Set<FriendshipTier> {
    switch self {
    case .cerchio: return [.inner]
    case .tutti: return [.inner, .close, .orbit]
    }
  }
}

struct PulseEvent: Identifiable, Hashable {
  enum Kind: Hashable {
    case message(String)
    case photoPost(String)
    case textPost(String)
    case audioPost(String)
    case vibe(String)
    case moodChange(from: Mood?, to: Mood)
  }

  let id: String
  var person: DemoPerson
  var kind: Kind
  var createdAt: Date
  var isMine: Bool = false
  var audience: PulseScope = .cerchio

  var isLive: Bool {
    Date.now.timeIntervalSince(createdAt) <= 30 * 60
  }
}

struct PulseEventGroup: Identifiable, Hashable {
  enum Moment: Int, CaseIterable, Hashable {
    case adesso
    case prima
    case ieri

    var title: String {
      switch self {
      case .adesso: return "Adesso"
      case .prima: return "Prima"
      case .ieri: return "Ieri"
      }
    }
  }

  let moment: Moment
  var events: [PulseEvent]

  var id: Moment { moment }
}

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
      case .innerClose: return "Cerchio"
      case .orbit:      return "Orbita"
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
  var localEvents: [PulseEvent] = []
  var isLoading: Bool = false
  var lastError: String?

  // Realtime: in `.live` ci si sottoscrive a FeedRealtime; in `.seed` resta nil.
  private let realtime = FeedRealtime()
  private var realtimeTask: Task<Void, Never>?

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
      startRealtime()
    }
  }

  /// Sottoscrivi i cambi live e re-load del feed quando arriva un evento.
  private func startRealtime() {
    realtimeTask?.cancel()
    realtimeTask = Task { @MainActor [weak self] in
      guard let self else { return }
      for await event in self.realtime.subscribe() {
        // Strategia minimale: marca lastError nil e ricarica.
        // Quando MomentItem reali sostituiscono DemoPerson, qui verrà fatto un
        // upsert mirato (single-event) invece del re-fetch completo.
        switch event {
        case .newPost, .newVibe, .newReaction:
          await self.load()
        }
      }
    }
  }

  func stopRealtime() async {
    realtimeTask?.cancel()
    realtimeTask = nil
    await realtime.disconnect()
  }

  // MARK: - derivate

  /// Default legacy: Pulse parte dal Cerchio.
  var pulsePeople: [DemoPerson] {
    pulsePeople(in: .cerchio)
  }

  func pulsePeople(in scope: PulseScope) -> [DemoPerson] {
    people
      .filter { $0.isMutual && scope.visibleTiers.contains($0.tier) }
      .sorted { lhs, rhs in
        if lhs.tier.rank != rhs.tier.rank { return lhs.tier.rank > rhs.tier.rank }
        return (lhs.lastPostAt ?? .distantPast) > (rhs.lastPostAt ?? .distantPast)
      }
  }

  func pulseAudienceSummary(in scope: PulseScope) -> String {
    "\(pulsePeople(in: scope).count) persone"
  }

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
    dominantMood(in: .cerchio, visibleLimit: visibleLimit)
  }

  func dominantMood(in scope: PulseScope, visibleLimit: Int = 6) -> Mood? {
    let head = pulsePeople(in: scope).filter(\.hasActiveVibe).prefix(visibleLimit)
    guard !head.isEmpty else { return nil }
    let counts = Dictionary(head.map { ($0.mood, 1) }, uniquingKeysWith: +)
    return counts.max(by: { $0.value < $1.value })?.key
  }

  var pulseEvents: [PulseEvent] {
    pulseEvents(in: .cerchio)
  }

  func pulseEvents(in scope: PulseScope) -> [PulseEvent] {
    let visibleLocalEvents = localEvents.filter { event in
      scope == .tutti || event.audience == .cerchio
    }
    return (visibleLocalEvents + demoEvents(in: scope))
      .sorted { lhs, rhs in lhs.createdAt > rhs.createdAt }
  }

  var pulseEventGroups: [PulseEventGroup] {
    pulseEventGroups(in: .cerchio)
  }

  func pulseEventGroups(in scope: PulseScope) -> [PulseEventGroup] {
    let grouped = Dictionary(grouping: pulseEvents(in: scope), by: { moment(for: $0.createdAt) })
    return PulseEventGroup.Moment.allCases.compactMap { moment in
      guard let events = grouped[moment], !events.isEmpty else { return nil }
      return PulseEventGroup(moment: moment, events: events)
    }
  }

  var liveEventCount: Int {
    liveEventCount(in: .cerchio)
  }

  func liveEventCount(in scope: PulseScope) -> Int {
    pulseEvents(in: scope).filter(\.isLive).count
  }

  func addLocalMessage(_ text: String, audience: PulseScope = .cerchio, mood: Mood = SeedPeople.me.mood) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    var me = SeedPeople.me
    me.mood = mood
    me.note = trimmed
    me.lastPostAt = .now
    me.hasActiveVibe = true
    localEvents.insert(
      PulseEvent(
        id: "local-message-\(UUID().uuidString)",
        person: me,
        kind: .message(trimmed),
        createdAt: .now,
        isMine: true,
        audience: audience
      ),
      at: 0
    )
  }

  func addLocalPlaceholder(_ kind: PulseEvent.Kind, audience: PulseScope = .cerchio) {
    var me = SeedPeople.me
    me.lastPostAt = .now
    me.hasActiveVibe = true
    localEvents.insert(
      PulseEvent(
        id: "local-\(UUID().uuidString)",
        person: me,
        kind: kind,
        createdAt: .now,
        isMine: true,
        audience: audience
      ),
      at: 0
    )
  }

  private func demoEvents(in scope: PulseScope) -> [PulseEvent] {
    pulsePeople(in: scope).flatMap { person -> [PulseEvent] in
      var events: [PulseEvent] = []
      let activity = person.lastPostAt ?? (person.hasActiveVibe ? Date.now.addingTimeInterval(-3600) : nil)

      if person.hasActiveVibe {
        let text = person.note.isEmpty ? "\(person.mood.rawValue), senza dire troppo" : person.note
        let kind: PulseEvent.Kind = bucket(for: person.id, salt: "vibe-kind") % 3 == 0
          ? .message(text)
          : .vibe(text)
        events.append(
          PulseEvent(
            id: "\(person.id)-vibe",
            person: person,
            kind: kind,
            createdAt: activity ?? Date.now.addingTimeInterval(-3600),
            audience: person.tier == .inner ? .cerchio : .tutti
          )
        )
      }

      if let lastPostAt = person.lastPostAt {
        let caption = person.note.isEmpty ? fallbackCaption(for: person) : person.note
        let postKind: PulseEvent.Kind
        switch bucket(for: person.id, salt: "post-kind") % 3 {
        case 0: postKind = .photoPost(caption)
        case 1: postKind = .textPost(caption)
        default: postKind = .audioPost(caption.isEmpty ? "voice note · 14s" : caption)
        }
        events.append(
          PulseEvent(
            id: "\(person.id)-post",
            person: person,
            kind: postKind,
            createdAt: lastPostAt,
            audience: person.tier == .inner ? .cerchio : .tutti
          )
        )

        if bucket(for: person.id, salt: "mood-change") % 5 == 0 {
          events.append(
            PulseEvent(
              id: "\(person.id)-mood",
              person: person,
              kind: .moodChange(from: nil, to: person.mood),
              createdAt: lastPostAt.addingTimeInterval(-18 * 60),
              audience: person.tier == .inner ? .cerchio : .tutti
            )
          )
        }
      }

      return events
    }
  }

  private func moment(for date: Date) -> PulseEventGroup.Moment {
    let age = Date.now.timeIntervalSince(date)
    if age <= 30 * 60 { return .adesso }
    if age <= 24 * 3600 { return .prima }
    return .ieri
  }

  private func bucket(for id: String, salt: String) -> UInt32 {
    var h: UInt32 = 5381
    for u in "\(id)|\(salt)".unicodeScalars {
      h = h &* 33 &+ u.value
    }
    return h
  }

  private func fallbackCaption(for person: DemoPerson) -> String {
    switch person.mood {
    case .warm: return "luce calda, poco rumore"
    case .focused: return "ancora sui libri"
    case .wild: return "fuori tra poco"
    case .chill: return "serata bassa"
    case .electric: return "volume alto"
    case .blue: return "aria strana"
    case .soft: return "casa e silenzio"
    case .lost: return "non so bene dove sono"
    }
  }
}
