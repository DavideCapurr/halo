import Foundation

public struct Profile: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public var handle: String
  public var displayName: String
  public var avatarPath: String?
  public var bio: String?
  public var hasPlus: Bool
  public var createdAt: Date

  public init(
    id: UUID,
    handle: String,
    displayName: String,
    avatarPath: String? = nil,
    bio: String? = nil,
    hasPlus: Bool = false,
    createdAt: Date = .now
  ) {
    self.id = id
    self.handle = handle
    self.displayName = displayName
    self.avatarPath = avatarPath
    self.bio = bio
    self.hasPlus = hasPlus
    self.createdAt = createdAt
  }

  enum CodingKeys: String, CodingKey {
    case id, handle, bio
    case displayName = "display_name"
    case avatarPath  = "avatar_path"
    case hasPlus     = "has_plus"
    case createdAt   = "created_at"
  }
}
