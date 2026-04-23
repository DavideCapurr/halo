import Foundation
import HaloShared

@MainActor
final class ReactionsService {
  static let shared = ReactionsService()
  private init() {}

  enum ReactionsError: Error { case notImplemented }

  struct Aggregate: Sendable {
    public let kind: ReactionKind
    public let count: Int
    /// Popolato solo se il viewer è Inner/Close dell'autore; altrimenti nil.
    public let actors: [UUID]?
  }

  func react(to postId: UUID, with kind: ReactionKind) async throws {
    throw ReactionsError.notImplemented // TODO step 10
  }

  func unreact(to postId: UUID, kind: ReactionKind) async throws {
    throw ReactionsError.notImplemented // TODO step 10
  }

  func reactions(for postId: UUID, viewerTier: FriendshipTier) async throws -> [Aggregate] {
    throw ReactionsError.notImplemented // TODO step 10
  }
}
