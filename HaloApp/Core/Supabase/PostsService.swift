import Foundation
import HaloShared

@MainActor
final class PostsService {
  static let shared = PostsService()
  private init() {}

  enum PostsError: Error { case notImplemented }

  func post(kind: PostKind, mediaPath: String?, caption: String?, mood: Mood?, minTier: FriendshipTier) async throws -> HaloPost {
    throw PostsError.notImplemented // TODO step 6
  }

  func delete(id: UUID) async throws {
    throw PostsError.notImplemented // TODO step 6
  }

  /// Post non scaduti dell'utente visibili al viewer corrente (RLS applica il filtro).
  func posts(forUser userId: UUID) async throws -> [HaloPost] {
    throw PostsError.notImplemented // TODO step 9
  }
}
