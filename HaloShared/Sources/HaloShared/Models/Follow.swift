import Foundation

public struct Follow: Codable, Hashable, Sendable {
  public let followerId: UUID
  public let followeeId: UUID
  public var tier: FriendshipTier
  public var proposedTier: FriendshipTier?
  public var proposedBy: UUID?
  public let createdAt: Date

  public init(
    followerId: UUID,
    followeeId: UUID,
    tier: FriendshipTier = .nebula,
    proposedTier: FriendshipTier? = nil,
    proposedBy: UUID? = nil,
    createdAt: Date = .now
  ) {
    self.followerId = followerId
    self.followeeId = followeeId
    self.tier = tier
    self.proposedTier = proposedTier
    self.proposedBy = proposedBy
    self.createdAt = createdAt
  }

  public var hasPendingProposal: Bool { proposedTier != nil }

  enum CodingKeys: String, CodingKey {
    case tier
    case followerId   = "follower_id"
    case followeeId   = "followee_id"
    case proposedTier = "proposed_tier"
    case proposedBy   = "proposed_by"
    case createdAt    = "created_at"
  }
}
