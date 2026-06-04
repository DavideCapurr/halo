import Foundation
import Observation
import HaloShared

/// View model condiviso da HomeView e PulseFeedView.
/// Fonde follows + profiles + vibes + post in `feedItems` (vedi `MomentItem`).
@Observable
@MainActor
final class HomeViewModel {
  // Dati grezzi (utili per debugging/inspector)
  var follows: [Follow] = []
  var profiles: [UUID: Profile] = [:]
  var vibes: [UUID: Vibe] = [:]
  var posts: [HaloPost] = []

  // Set degli userId con cui il viewer ha follow reciproci.
  var mutualIds: Set<UUID> = []

  // Stato di caricamento
  var isLoading: Bool = false
  var lastError: String?

  /// Items del feed/orbital, già ordinati per tier desc.
  /// Mutuali → bolle dell'orbital field. Non mutuali → asteroidi.
  var feedItems: [MomentItem] = []

  var mutualItems: [MomentItem] {
    feedItems.filter { $0.isMutual }
  }

  var asteroidItems: [MomentItem] {
    feedItems.filter { !$0.isMutual }
  }

  func load() async {
    isLoading = true
    defer { isLoading = false }
    do {
      // 1. follows del viewer + post visibili (RLS) in parallelo
      async let myFollowsTask = FollowsService.shared.myFollows()
      async let feedTask = PostsService.shared.feedPosts()
      async let blockedTask = ReportsService.shared.blockedIds()

      let blockedIds = try await blockedTask
      let rawFollows = try await myFollowsTask
      let rawFeed = try await feedTask
      let myFollows = rawFollows.filter { !blockedIds.contains($0.followeeId) }
      let feed = rawFeed.filter { !blockedIds.contains($0.userId) }
      self.follows = myFollows
      self.posts = feed

      // 2. set utenti rilevanti = followee + autori dei post
      let followeeIds = myFollows.map(\.followeeId)
      let authorIds = feed.map(\.userId)
      let userIds = Array(Set(followeeIds + authorIds))
      guard !userIds.isEmpty else {
        self.profiles = [:]
        self.vibes = [:]
        self.mutualIds = []
        self.feedItems = []
        self.lastError = nil
        return
      }

      // 3. profili + vibe attive + mutual set in parallelo
      async let profilesTask = fetchProfiles(ids: userIds)
      async let vibesTask = VibesService.shared.currentVibes(for: userIds)
      async let mutualsTask = FollowsService.shared.mutualSet(among: userIds)

      let fetchedProfiles = try await profilesTask
      let fetchedVibes = try await vibesTask
      let mutuals = try await mutualsTask

      self.profiles = fetchedProfiles
      self.vibes = fetchedVibes
      self.mutualIds = mutuals

      // 4. compone gli items
      let tierByAuthor: [UUID: FriendshipTier] = Dictionary(
        uniqueKeysWithValues: myFollows.map { ($0.followeeId, $0.tier) }
      )
      let lastPostByAuthor: [UUID: HaloPost] = Dictionary(
        feed.map { ($0.userId, $0) },
        uniquingKeysWith: { lhs, rhs in lhs.createdAt >= rhs.createdAt ? lhs : rhs }
      )

      var items: [MomentItem] = userIds.compactMap { uid in
        guard let p = fetchedProfiles[uid] else { return nil }
        return MomentItem(
          profile: p,
          viewerTier: tierByAuthor[uid],
          vibe: fetchedVibes[uid],
          lastPost: lastPostByAuthor[uid],
          isMutual: mutuals.contains(uid)
        )
      }
      // Tier desc, poi attività recente desc.
      items.sort { lhs, rhs in
        if lhs.sortRank != rhs.sortRank { return lhs.sortRank > rhs.sortRank }
        return lhs.lastActivityAt > rhs.lastActivityAt
      }
      self.feedItems = items
      self.lastError = nil

      // Aggiorna lo snapshot widget (App Group + reload timeline).
      try? WidgetSnapshotStore.refresh(from: items)
    } catch {
      self.lastError = SupabaseErrorMessage.describe(
        error,
        fallback: "Non riesco a caricare l'orbita. Riprova."
      )
    }
  }

  // MARK: - Helpers

  private func fetchProfiles(ids: [UUID]) async throws -> [UUID: Profile] {
    var out: [UUID: Profile] = [:]
    try await withThrowingTaskGroup(of: Profile?.self) { group in
      for id in ids {
        group.addTask {
          try? await ProfilesService.shared.profile(id: id)
        }
      }
      for try await p in group {
        if let p { out[p.id] = p }
      }
    }
    return out
  }
}
