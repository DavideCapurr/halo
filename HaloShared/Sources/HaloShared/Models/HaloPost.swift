import Foundation

public struct HaloPost: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public let userId: UUID
  public var kind: PostKind
  public var mediaPath: String?
  public var caption: String?
  public var mood: Mood?
  public var minTier: FriendshipTier
  public let createdAt: Date
  public let expiresAt: Date

  public var isAlive: Bool { expiresAt > .now }

  /// Finestra totale di vita del post (`expires_at - created_at`).
  public var totalLifespan: TimeInterval { expiresAt.timeIntervalSince(createdAt) }

  /// `true` se è un post "easy" (vita corta, low-stakes). Derivato dalla
  /// finestra di vita così non serve una colonna dedicata: i post easy hanno
  /// un `expires_at` molto più vicino al `created_at`.
  public var isEasy: Bool { totalLifespan <= PostLifespan.easy.duration + 60 }

  public init(
    id: UUID = UUID(),
    userId: UUID,
    kind: PostKind,
    mediaPath: String? = nil,
    caption: String? = nil,
    mood: Mood? = nil,
    minTier: FriendshipTier = .inner,
    createdAt: Date = .now,
    expiresAt: Date? = nil,
    lifespan: PostLifespan = .standard
  ) {
    self.id = id
    self.userId = userId
    self.kind = kind
    self.mediaPath = mediaPath
    self.caption = caption
    self.mood = mood
    self.minTier = minTier
    self.createdAt = createdAt
    self.expiresAt = expiresAt ?? createdAt.addingTimeInterval(lifespan.duration)
  }

  enum CodingKeys: String, CodingKey {
    case id, kind, caption, mood
    case userId    = "user_id"
    case mediaPath = "media_path"
    case minTier   = "min_tier"
    case createdAt = "created_at"
    case expiresAt = "expires_at"
  }
}
