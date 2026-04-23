import Foundation

/// Payload minimale che l'app condivide col widget via App Group.
/// Il widget legge questo da un file JSON in `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`.
public struct WidgetSnapshot: Codable, Sendable {
  public struct Bubble: Codable, Hashable, Sendable {
    public let userId: UUID
    public let handle: String
    public let displayName: String
    public let avatarPath: String?
    public let mood: Mood?
    public let colorHex: String?
    public let tier: FriendshipTier

    public init(userId: UUID, handle: String, displayName: String, avatarPath: String?, mood: Mood?, colorHex: String?, tier: FriendshipTier) {
      self.userId = userId
      self.handle = handle
      self.displayName = displayName
      self.avatarPath = avatarPath
      self.mood = mood
      self.colorHex = colorHex
      self.tier = tier
    }
  }

  public let generatedAt: Date
  public let bubbles: [Bubble]

  public init(generatedAt: Date = .now, bubbles: [Bubble]) {
    self.generatedAt = generatedAt
    self.bubbles = bubbles
  }

  public static let filename = "halo_widget_snapshot.json"
}
