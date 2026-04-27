import Foundation
import HaloShared
import Supabase

@MainActor
final class PostsService {
  static let shared = PostsService()
  private init() {}

  enum PostsError: Error { case notAuthenticated }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  /// Crea un nuovo post per l'utente corrente. RLS impone `user_id = auth.uid()`.
  @discardableResult
  func post(
    kind: PostKind,
    mediaPath: String?,
    caption: String?,
    mood: Mood?,
    minTier: FriendshipTier = .inner
  ) async throws -> HaloPost {
    guard let userId = AuthService.shared.currentUserId() else {
      throw PostsError.notAuthenticated
    }
    let draft = HaloPost(
      userId: userId,
      kind: kind,
      mediaPath: mediaPath,
      caption: caption,
      mood: mood,
      minTier: minTier
    )
    let inserted: HaloPost = try await client
      .from("halo_posts")
      .insert(draft)
      .select()
      .single()
      .execute()
      .value
    return inserted
  }

  func delete(id: UUID) async throws {
    try await client
      .from("halo_posts")
      .delete()
      .eq("id", value: id)
      .execute()
  }

  /// Post non scaduti dell'utente visibili al viewer corrente (RLS applica il filtro).
  func posts(forUser userId: UUID) async throws -> [HaloPost] {
    try await client
      .from("halo_posts")
      .select()
      .eq("user_id", value: userId)
      .gt("expires_at", value: Date.now.iso8601String)
      .order("created_at", ascending: false)
      .execute()
      .value
  }

  /// Home feed: tutti i post vivi visibili al viewer (RLS gating), ordinati per
  /// `tier_rank DESC` (Inner prima) e a parità di tier per `created_at DESC`.
  /// Il tier del viewer verso ciascun autore arriva da `myFollows()`.
  func feedPosts() async throws -> [HaloPost] {
    async let postsTask: [HaloPost] = client
      .from("halo_posts")
      .select()
      .gt("expires_at", value: Date.now.iso8601String)
      .order("created_at", ascending: false)
      .execute()
      .value
    async let followsTask = FollowsService.shared.myFollows()

    let posts = try await postsTask
    let follows = try await followsTask
    let tierByAuthor: [UUID: FriendshipTier] = Dictionary(
      uniqueKeysWithValues: follows.map { ($0.followeeId, $0.tier) }
    )

    return posts.sorted { lhs, rhs in
      let lr = tierByAuthor[lhs.userId]?.rank ?? 0
      let rr = tierByAuthor[rhs.userId]?.rank ?? 0
      if lr != rr { return lr > rr }
      return lhs.createdAt > rhs.createdAt
    }
  }
}

private extension Date {
  var iso8601String: String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.string(from: self)
  }
}
