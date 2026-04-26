import Foundation
import HaloShared
import Supabase

@MainActor
final class ReactionsService {
  static let shared = ReactionsService()
  private init() {}

  enum ReactionsError: Error { case notAuthenticated }

  struct Aggregate: Sendable {
    public let kind: ReactionKind
    public let count: Int
    /// Popolato solo se il viewer è Inner/Close dell'autore; altrimenti nil.
    public let actors: [UUID]?
  }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  func react(to postId: UUID, with kind: ReactionKind) async throws {
    guard let me = AuthService.shared.currentUserId() else {
      throw ReactionsError.notAuthenticated
    }
    let row = Reaction(postId: postId, actorId: me, kind: kind)
    try await client
      .from("reactions")
      .insert(row)
      .execute()
  }

  func unreact(to postId: UUID, kind: ReactionKind) async throws {
    guard let me = AuthService.shared.currentUserId() else {
      throw ReactionsError.notAuthenticated
    }
    try await client
      .from("reactions")
      .delete()
      .eq("post_id", value: postId)
      .eq("actor_id", value: me)
      .eq("kind", value: kind.rawValue)
      .execute()
  }

  /// Aggrega le reazioni per kind. Per i tier `inner` / `close` espone gli `actors`
  /// (chi ha reagito), per `orbit` / `nebula` solo il count, come da spec UX.
  func reactions(for postId: UUID, viewerTier: FriendshipTier) async throws -> [Aggregate] {
    let rows: [Reaction] = try await client
      .from("reactions")
      .select()
      .eq("post_id", value: postId)
      .execute()
      .value

    let exposeActors = (viewerTier == .inner || viewerTier == .close)
    let grouped = Dictionary(grouping: rows, by: \.kind)
    return ReactionKind.allCases.compactMap { kind in
      guard let bucket = grouped[kind], !bucket.isEmpty else { return nil }
      return Aggregate(
        kind: kind,
        count: bucket.count,
        actors: exposeActors ? bucket.map(\.actorId) : nil
      )
    }
  }
}
