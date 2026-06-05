import Foundation
import Observation
import HaloShared

enum PulseScope: String, CaseIterable, Hashable, Identifiable {
  case inner
  case tutti

  var id: String { rawValue }

  var title: String {
    switch self {
    case .inner: return "Inner"
    case .tutti: return "Tutti"
    }
  }

  var subtitle: String {
    switch self {
    case .inner: return "solo Inner"
    case .tutti: return "tutte le tue orbite"
    }
  }

  var visibleTiers: Set<FriendshipTier> {
    switch self {
    case .inner: return [.inner]
    case .tutti: return [.inner, .close, .orbit]
    }
  }

  var presentation: HaloScopePresentation {
    .init(id: id, title: title, subtitle: subtitle, visibleTiers: visibleTiers)
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
  var person: HaloPersonNode
  var kind: Kind
  var createdAt: Date
  var isMine: Bool = false
  var audience: PulseScope = .inner

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
/// In live mode it hydrates the presentation nodes from `HomeViewModel`.
/// Seed mode remains available for previews and offline design iteration.
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
      case .innerClose: return "Inner · Close"
      case .orbit:      return "Orbita"
      case .nebula:     return "Nebula"
      }
    }

    static func from(tier: FriendshipTier) -> FeedSection {
      switch tier {
      case .inner, .close:   return .innerClose
      case .orbit:           return .orbit
      case .nebula:          return .nebula
      case .asteroid:        return .nebula
      }
    }
  }

  // Stato di base
  private let bootstrap: Bootstrap
  private let home = HomeViewModel()
  var people: [HaloPersonNode] = []
  var localEvents: [PulseEvent] = []
  var isLoading: Bool = false
  var isPublishing: Bool = false
  var lastError: String?

  // Realtime: in `.live` ci si sottoscrive a FeedRealtime; in `.seed` resta nil.
  private let realtime = FeedRealtime()
  private var realtimeTask: Task<Void, Never>?
  private var actorLabelCache: [UUID: String] = [:]
  private var appliedReactionKeys: Set<String> = []

  init(bootstrap: Bootstrap = .live) {
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
      await home.load()
      let liveNodes = await presentationNodes(from: home.feedItems.filter(\.isMutual))
      self.people = liveNodes
      self.lastError = home.lastError
      startRealtime()
    }
  }

  /// Sottoscrive i cambi live e applica patch mirate al feed corrente.
  private func startRealtime() {
    guard bootstrap == .live else { return }
    realtimeTask?.cancel()
    realtimeTask = Task { @MainActor [weak self] in
      guard let self else { return }
      for await event in self.realtime.subscribe() {
        await self.applyRealtime(event)
      }
    }
  }

  func stopRealtime() async {
    realtimeTask?.cancel()
    realtimeTask = nil
    await realtime.disconnect()
  }

  // MARK: - derivate

  /// Default legacy: Pulse parte da Inner.
  var pulsePeople: [HaloPersonNode] {
    pulsePeople(in: .inner)
  }

  func pulsePeople(in scope: PulseScope) -> [HaloPersonNode] {
    people
      .filter { $0.isMutual && scope.visibleTiers.contains($0.tier) }
      .sorted { lhs, rhs in
        if lhs.tier.rank != rhs.tier.rank { return lhs.tier.rank > rhs.tier.rank }
        return (lhs.lastActivityAt ?? .distantPast) > (rhs.lastActivityAt ?? .distantPast)
      }
  }

  func pulseAudienceSummary(in scope: PulseScope) -> String {
    "\(pulsePeople(in: scope).count) persone"
  }

  /// Persone con post negli ultimi 30 min (sezione "Adesso").
  /// Ordinate per ultimo post desc.
  var adessoItems: [HaloPersonNode] {
    people
      .filter { p in
        guard let t = p.lastActivityAt else { return false }
        return Date.now.timeIntervalSince(t) <= 30 * 60
      }
      .sorted { (a, b) in (a.lastActivityAt ?? .distantPast) > (b.lastActivityAt ?? .distantPast) }
  }

  /// Persone con vibe attiva, tier-sorted (Inner prima).
  /// Alimenta la `PresenceBar` in cima al feed.
  var presenceItems: [HaloPersonNode] {
    people
      .filter(\.hasActiveVibe)
      .sorted { (a, b) in
        if a.tier.rank != b.tier.rank { return a.tier.rank > b.tier.rank }
        return (a.lastActivityAt ?? .distantPast) > (b.lastActivityAt ?? .distantPast)
      }
  }

  /// Sezioni del feed (Inner&Close / Orbit / Nebula), ognuna ordinata per
  /// "ultima attività" desc (= ultimo post; fallback su vibe attiva).
  var sections: [(FeedSection, [HaloPersonNode])] {
    let grouped = Dictionary(grouping: people, by: { FeedSection.from(tier: $0.tier) })
    return FeedSection.allCases.compactMap { section in
      guard let items = grouped[section], !items.isEmpty else { return nil }
      let sorted = items.sorted { (a, b) in
        let ta = a.lastActivityAt ?? .distantPast
        let tb = b.lastActivityAt ?? .distantPast
        return ta > tb
      }
      return (section, sorted)
    }
  }

  /// Mood dominante delle prime card visibili (per la tinta del background).
  /// nil se nessuna persona ha una vibe attiva tra le prime N.
  func dominantMood(visibleLimit: Int = 6) -> Mood? {
    dominantMood(in: .inner, visibleLimit: visibleLimit)
  }

  func dominantMood(in scope: PulseScope, visibleLimit: Int = 6) -> Mood? {
    let head = pulsePeople(in: scope).filter(\.hasActiveVibe).prefix(visibleLimit)
    guard !head.isEmpty else { return nil }
    let counts = Dictionary(head.map { ($0.mood, 1) }, uniquingKeysWith: +)
    return counts.max(by: { $0.value < $1.value })?.key
  }

  var pulseEvents: [PulseEvent] {
    pulseEvents(in: .inner)
  }

  func pulseEvents(in scope: PulseScope) -> [PulseEvent] {
    let visibleLocalEvents = localEvents.filter { event in
      scope == .tutti || event.audience == .inner
    }
    let sourceEvents = bootstrap == .seed ? demoEvents(in: scope) : liveEvents(in: scope)
    return (visibleLocalEvents + sourceEvents)
      .sorted { lhs, rhs in lhs.createdAt > rhs.createdAt }
  }

  var pulseEventGroups: [PulseEventGroup] {
    pulseEventGroups(in: .inner)
  }

  func pulseEventGroups(in scope: PulseScope) -> [PulseEventGroup] {
    let grouped = Dictionary(grouping: pulseEvents(in: scope), by: { moment(for: $0.createdAt) })
    return PulseEventGroup.Moment.allCases.compactMap { moment in
      guard let events = grouped[moment], !events.isEmpty else { return nil }
      return PulseEventGroup(moment: moment, events: events)
    }
  }

  var liveEventCount: Int {
    liveEventCount(in: .inner)
  }

  func liveEventCount(in scope: PulseScope) -> Int {
    pulseEvents(in: scope).filter(\.isLive).count
  }

  func publishMessage(_ text: String, audience: PulseScope = .inner, mood: Mood = SeedPeople.me.mood) async {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    isPublishing = true
    defer { isPublishing = false }

    var me = await currentViewerNode(mood: mood, note: trimmed)
    me.mood = mood
    me.note = trimmed
    me.lastPostAt = .now
    me.lastPostKind = .text
    me.lastPostCaption = trimmed
    me.hasActiveVibe = true

    let localId = "local-message-\(UUID().uuidString)"
    localEvents.insert(
      PulseEvent(id: localId, person: me, kind: .message(trimmed), createdAt: .now, isMine: true, audience: audience),
      at: 0
    )

    do {
      let post = try await PostsService.shared.post(
        kind: .text,
        mediaPath: nil,
        caption: trimmed,
        mood: mood,
        minTier: audience.minTier
      )
      if let index = localEvents.firstIndex(where: { $0.id == localId }) {
        localEvents[index].person.apply(post: post)
        localEvents[index].kind = .textPost(trimmed)
        localEvents[index].createdAt = post.createdAt
      }
      await applyPost(post)
      lastError = nil
    } catch {
      localEvents.removeAll { $0.id == localId }
      lastError = SupabaseErrorMessage.describe(error, fallback: "Non riesco a mandare il Moment. Riprova.")
    }
  }

  func publishQuickDrop(_ type: PulseDropKind, audience: PulseScope = .inner, mood: Mood = SeedPeople.me.mood, note: String = "") async {
    isPublishing = true
    defer { isPublishing = false }

    let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
    var me = await currentViewerNode(mood: mood, note: trimmed)
    me.mood = mood
    me.note = trimmed
    me.hasActiveVibe = true

    let localId = "local-\(UUID().uuidString)"

    do {
      switch type {
      case .vibe:
        let vibe = try await VibesService.shared.setCurrent(
          mood: mood,
          colorHex: mood.defaultHex,
          note: trimmed.isEmpty ? nil : trimmed
        )
        me.apply(vibe: vibe)
        localEvents.insert(
          PulseEvent(
            id: localId,
            person: me,
            kind: .vibe(trimmed.isEmpty ? mood.rawValue : trimmed),
            createdAt: vibe.createdAt,
            isMine: true,
            audience: audience
          ),
          at: 0
        )
        await applyVibe(vibe)

      case .photo:
        let post = try await PostsService.shared.post(
          kind: .photo,
          mediaPath: nil,
          caption: trimmed.isEmpty ? nil : trimmed,
          mood: mood,
          minTier: audience.minTier
        )
        me.apply(post: post)
        localEvents.insert(
          PulseEvent(id: localId, person: me, kind: .photoPost(post.caption ?? ""), createdAt: post.createdAt, isMine: true, audience: audience),
          at: 0
        )
        await applyPost(post)

      case .audio:
        let post = try await PostsService.shared.post(
          kind: .audio,
          mediaPath: nil,
          caption: trimmed.isEmpty ? nil : trimmed,
          mood: mood,
          minTier: audience.minTier
        )
        me.apply(post: post)
        localEvents.insert(
          PulseEvent(id: localId, person: me, kind: .audioPost(post.caption ?? ""), createdAt: post.createdAt, isMine: true, audience: audience),
          at: 0
        )
        await applyPost(post)
      }
      lastError = nil
    } catch {
      localEvents.removeAll { $0.id == localId }
      lastError = SupabaseErrorMessage.describe(error, fallback: "Non riesco a mandare il drop. Riprova.")
    }
  }

  func react(to event: PulseEvent, with kind: ReactionKind) async {
    guard let postId = event.person.lastPostId else { return }
    do {
      let actorId = AuthService.shared.currentUserId()
      try await ReactionsService.shared.react(to: postId, with: kind)
      if let actorId {
        await applyReaction(Reaction(postId: postId, actorId: actorId, kind: kind))
      } else {
        await refreshReactionTallies(for: postId)
      }
      lastError = nil
    } catch {
      lastError = SupabaseErrorMessage.describe(error, fallback: "Non riesco a mandare la reazione. Riprova.")
    }
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
            audience: person.tier == .inner ? .inner : .tutti
          )
        )
      }

      if let lastPostAt = person.lastPostAt {
        let caption = person.lastPostCaption ?? person.note
        let postKind: PulseEvent.Kind
        switch bucket(for: person.id, salt: "post-kind") % 3 {
        case 0: postKind = .photoPost(caption)
        case 1: postKind = .textPost(caption)
        default: postKind = .audioPost(caption)
        }
        events.append(
          PulseEvent(
            id: "\(person.id)-post",
            person: person,
            kind: postKind,
            createdAt: lastPostAt,
            audience: person.tier == .inner ? .inner : .tutti
          )
        )

        if bucket(for: person.id, salt: "mood-change") % 5 == 0 {
          events.append(
            PulseEvent(
              id: "\(person.id)-mood",
              person: person,
              kind: .moodChange(from: nil, to: person.mood),
              createdAt: lastPostAt.addingTimeInterval(-18 * 60),
              audience: person.tier == .inner ? .inner : .tutti
            )
          )
        }
      }

      return events
    }
  }

  private func liveEvents(in scope: PulseScope) -> [PulseEvent] {
    pulsePeople(in: scope).flatMap { person -> [PulseEvent] in
      var events: [PulseEvent] = []

      if person.hasActiveVibe {
        let text = person.note.isEmpty ? person.mood.rawValue : person.note
        events.append(
          PulseEvent(
            id: "\(person.id)-live-vibe",
            person: person,
            kind: .vibe(text),
            createdAt: person.lastVibeAt ?? person.lastActivityAt ?? Date.now,
            audience: person.tier == .inner ? .inner : .tutti
          )
        )
      }

      if let lastPostAt = person.lastPostAt {
        let caption = person.lastPostCaption ?? ""
        events.append(
          PulseEvent(
            id: person.lastPostId?.uuidString ?? "\(person.id)-live-post",
            person: person,
            kind: Self.eventKind(for: person.lastPostKind, caption: caption),
            createdAt: lastPostAt,
            audience: person.tier == .inner ? .inner : .tutti
          )
        )
      }

      return events
    }
  }

  private static func eventKind(for postKind: PostKind?, caption: String) -> PulseEvent.Kind {
    switch postKind {
    case .photo:
      return .photoPost(caption)
    case .audio:
      return .audioPost(caption)
    case .text:
      return .textPost(caption)
    case nil:
      return .textPost(caption)
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

}

enum PulseDropKind {
  case photo
  case audio
  case vibe
}

private extension PulseScope {
  var minTier: FriendshipTier {
    switch self {
    case .inner: return .inner
    case .tutti: return .orbit
    }
  }
}

private extension FeedViewModel {
  func presentationNodes(from items: [MomentItem]) async -> [HaloPersonNode] {
    var nodes: [HaloPersonNode] = []
    for item in items {
      var node = HaloPersonNode(item: item)
      if let post = item.lastPost {
        node.lastPostReactionTallies = await reactionTallies(for: post, viewerTier: node.tier)
      }
      nodes.append(node)
    }
    return nodes
  }

  func applyRealtime(_ event: FeedRealtime.Event) async {
    switch event {
    case .newPost(let post):
      await applyPost(post)
    case .newVibe(let vibe):
      await applyVibe(vibe)
    case .newReaction(let reaction):
      await applyReaction(reaction)
    }
  }

  func applyPost(_ post: HaloPost) async {
    guard post.isAlive else { return }

    if let index = people.firstIndex(where: { $0.id == post.userId.uuidString }) {
      let current = people[index].lastPostAt ?? .distantPast
      guard post.createdAt >= current else { return }
      people[index].apply(post: post)
      people[index].lastPostReactionTallies = await reactionTallies(for: post, viewerTier: people[index].tier)
      sortPeople()
      refreshLocalEvents(for: post.userId, post: post)
      return
    }

    if let node = await hydratePersonNode(userId: post.userId, overridingPost: post) {
      people.append(node)
      sortPeople()
    }
  }

  func applyVibe(_ vibe: Vibe) async {
    guard vibe.isActive else { return }

    if let index = people.firstIndex(where: { $0.id == vibe.userId.uuidString }) {
      people[index].apply(vibe: vibe)
      sortPeople()
      refreshLocalEvents(for: vibe.userId, vibe: vibe)
      return
    }

    if let node = await hydratePersonNode(userId: vibe.userId, overridingVibe: vibe) {
      people.append(node)
      sortPeople()
    }
  }

  func applyReaction(_ reaction: Reaction) async {
    let reactionKey = "\(reaction.postId.uuidString)|\(reaction.actorId.uuidString)|\(reaction.kind.rawValue)"
    guard appliedReactionKeys.insert(reactionKey).inserted else { return }

    let label = await actorLabel(for: reaction.actorId)

    if let index = people.firstIndex(where: { $0.lastPostId == reaction.postId }) {
      people[index].addReaction(kind: reaction.kind, actorLabel: people[index].canExposeReactionActors ? label : nil)
    }

    for index in localEvents.indices where localEvents[index].person.lastPostId == reaction.postId {
      localEvents[index].person.addReaction(
        kind: reaction.kind,
        actorLabel: localEvents[index].person.canExposeReactionActors ? label : nil
      )
    }
  }

  func refreshReactionTallies(for postId: UUID) async {
    if let index = people.firstIndex(where: { $0.lastPostId == postId }) {
      people[index].lastPostReactionTallies = await reactionTallies(forPostId: postId, viewerTier: people[index].tier)
    }
    for index in localEvents.indices where localEvents[index].person.lastPostId == postId {
      localEvents[index].person.lastPostReactionTallies = await reactionTallies(
        forPostId: postId,
        viewerTier: localEvents[index].person.tier
      )
    }
  }

  func hydratePersonNode(userId: UUID, overridingPost: HaloPost? = nil, overridingVibe: Vibe? = nil) async -> HaloPersonNode? {
    do {
      if try await ReportsService.shared.blockedIds().contains(userId) { return nil }

      let profile = try await ProfilesService.shared.profile(id: userId)
      let follows = try await FollowsService.shared.myFollows()
      let mutuals = try await FollowsService.shared.mutualSet(among: [userId])
      guard mutuals.contains(userId) else { return nil }

      let tier = follows.first(where: { $0.followeeId == userId })?.tier
      let vibe: Vibe?
      if let overridingVibe {
        vibe = overridingVibe
      } else {
        vibe = try await VibesService.shared.current(for: userId)
      }
      let post: HaloPost?
      if let overridingPost {
        post = overridingPost
      } else {
        let latestPosts = try await PostsService.shared.posts(forUser: userId)
        post = latestPosts.first
      }

      var node = HaloPersonNode(
        item: MomentItem(
          profile: profile,
          viewerTier: tier,
          vibe: vibe,
          lastPost: post,
          isMutual: true
        )
      )
      if let post {
        node.lastPostReactionTallies = await reactionTallies(for: post, viewerTier: node.tier)
      }
      return node
    } catch {
      return nil
    }
  }

  func currentViewerNode(mood: Mood, note: String) async -> HaloPersonNode {
    guard let userId = AuthService.shared.currentUserId(),
          let profile = try? await ProfilesService.shared.profile(id: userId) else {
      return SeedPeople.me
    }
    return HaloPersonNode(
      id: userId.uuidString,
      handle: profile.handle,
      name: profile.displayName,
      tier: .inner,
      mood: mood,
      note: note,
      hasNew: true,
      hasActiveVibe: true,
      isMutual: true
    )
  }

  func reactionTallies(for post: HaloPost, viewerTier: FriendshipTier) async -> [HaloReactionTally] {
    await reactionTallies(forPostId: post.id, viewerTier: viewerTier)
  }

  func reactionTallies(forPostId postId: UUID, viewerTier: FriendshipTier) async -> [HaloReactionTally] {
    do {
      let aggregates = try await ReactionsService.shared.reactions(for: postId, viewerTier: viewerTier)
      var tallies: [HaloReactionTally] = []
      for aggregate in aggregates {
        let labels = await actorLabels(for: aggregate.actors)
        tallies.append(HaloReactionTally(kind: aggregate.kind, count: aggregate.count, actorLabels: labels))
      }
      return tallies.sortedByReactionKind()
    } catch {
      return []
    }
  }

  func actorLabels(for actorIds: [UUID]?) async -> [String]? {
    guard let actorIds else { return nil }
    var labels: [String] = []
    for actorId in actorIds.prefix(3) {
      labels.append(await actorLabel(for: actorId))
    }
    return labels
  }

  func actorLabel(for actorId: UUID) async -> String {
    if let cached = actorLabelCache[actorId] { return cached }
    if let profile = try? await ProfilesService.shared.profile(id: actorId) {
      actorLabelCache[actorId] = profile.handle
      return profile.handle
    }
    let fallback = String(actorId.uuidString.prefix(4)).lowercased()
    actorLabelCache[actorId] = fallback
    return fallback
  }

  func sortPeople() {
    people.sort { lhs, rhs in
      if lhs.tier.rank != rhs.tier.rank { return lhs.tier.rank > rhs.tier.rank }
      return (lhs.lastActivityAt ?? .distantPast) > (rhs.lastActivityAt ?? .distantPast)
    }
  }

  func refreshLocalEvents(for userId: UUID, post: HaloPost) {
    for index in localEvents.indices where localEvents[index].person.id == userId.uuidString {
      localEvents[index].person.apply(post: post)
    }
  }

  func refreshLocalEvents(for userId: UUID, vibe: Vibe) {
    for index in localEvents.indices where localEvents[index].person.id == userId.uuidString {
      localEvents[index].person.apply(vibe: vibe)
    }
  }
}

private extension HaloPersonNode {
  var canExposeReactionActors: Bool {
    tier == .inner || tier == .close
  }

  mutating func apply(post: HaloPost) {
    lastPostAt = post.createdAt
    lastPostId = post.id
    lastPostKind = post.kind
    lastPostCaption = post.caption
    lastPostMediaPath = post.mediaPath
    lastPostExpiresAt = post.expiresAt
    lastPostReactionTallies = []
    hasNew = Date.now.timeIntervalSince(post.createdAt) <= 30 * 60
    if !hasActiveVibe {
      note = post.caption ?? ""
      mood = post.mood ?? mood
    }
  }

  mutating func apply(vibe: Vibe) {
    mood = vibe.mood
    note = vibe.note ?? ""
    hasActiveVibe = true
    lastVibeAt = vibe.createdAt
    hasNew = Date.now.timeIntervalSince(vibe.createdAt) <= 30 * 60
  }

  mutating func addReaction(kind: ReactionKind, actorLabel: String?) {
    if let index = lastPostReactionTallies.firstIndex(where: { $0.kind == kind }) {
      lastPostReactionTallies[index].count += 1
      if let actorLabel {
        var labels = lastPostReactionTallies[index].actorLabels ?? []
        if !labels.contains(actorLabel) {
          labels.append(actorLabel)
        }
        lastPostReactionTallies[index].actorLabels = Array(labels.prefix(3))
      }
    } else {
      lastPostReactionTallies.append(
        HaloReactionTally(kind: kind, count: 1, actorLabels: actorLabel.map { [$0] })
      )
    }
    lastPostReactionTallies = lastPostReactionTallies.sortedByReactionKind()
  }
}

private extension Array where Element == HaloReactionTally {
  func sortedByReactionKind() -> [HaloReactionTally] {
    sorted { lhs, rhs in
      let left = ReactionKind.allCases.firstIndex(of: lhs.kind) ?? 0
      let right = ReactionKind.allCases.firstIndex(of: rhs.kind) ?? 0
      return left < right
    }
  }
}
