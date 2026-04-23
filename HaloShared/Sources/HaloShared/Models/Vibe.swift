import Foundation

public struct Vibe: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public let userId: UUID
  public var mood: Mood
  public var colorHex: String
  public var note: String?
  public let createdAt: Date
  public let expiresAt: Date

  public var isActive: Bool { expiresAt > .now }

  public init(
    id: UUID = UUID(),
    userId: UUID,
    mood: Mood,
    colorHex: String,
    note: String? = nil,
    createdAt: Date = .now,
    expiresAt: Date = .now.addingTimeInterval(24 * 3600)
  ) {
    self.id = id
    self.userId = userId
    self.mood = mood
    self.colorHex = colorHex
    self.note = note
    self.createdAt = createdAt
    self.expiresAt = expiresAt
  }

  enum CodingKeys: String, CodingKey {
    case id, mood, note
    case userId    = "user_id"
    case colorHex  = "color_hex"
    case createdAt = "created_at"
    case expiresAt = "expires_at"
  }
}
