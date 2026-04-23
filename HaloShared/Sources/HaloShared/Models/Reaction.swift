import Foundation

public struct Reaction: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public let postId: UUID
  public let actorId: UUID
  public var kind: ReactionKind
  public let createdAt: Date

  public init(id: UUID = UUID(), postId: UUID, actorId: UUID, kind: ReactionKind, createdAt: Date = .now) {
    self.id = id
    self.postId = postId
    self.actorId = actorId
    self.kind = kind
    self.createdAt = createdAt
  }

  enum CodingKeys: String, CodingKey {
    case id, kind
    case postId    = "post_id"
    case actorId   = "actor_id"
    case createdAt = "created_at"
  }
}
