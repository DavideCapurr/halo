import Foundation
import HaloShared

@MainActor
final class FollowsService {
  static let shared = FollowsService()
  private init() {}

  enum FollowsError: Error { case notImplemented, promotionRequiresConfirmation }

  /// Crea una follow di default a `nebula`. Tier superiori richiedono proposta.
  func follow(_ userId: UUID) async throws -> Follow {
    throw FollowsError.notImplemented // TODO step 7
  }

  func unfollow(_ userId: UUID) async throws {
    throw FollowsError.notImplemented // TODO step 7
  }

  /// Drag-to-tier: chi si trascina propone il tier. L'altra parte conferma.
  func proposeTier(_ tier: FriendshipTier, for followeeId: UUID) async throws {
    throw FollowsError.notImplemented // TODO step 8
  }

  func acceptProposedTier(on followerId: UUID) async throws {
    throw FollowsError.notImplemented // TODO step 8
  }

  func declineProposedTier(on followerId: UUID) async throws {
    throw FollowsError.notImplemented // TODO step 8
  }

  /// Elenco follows del viewer (per popolare gli anelli home).
  func myFollows() async throws -> [Follow] {
    throw FollowsError.notImplemented // TODO step 8
  }
}
