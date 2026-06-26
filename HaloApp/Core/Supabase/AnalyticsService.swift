import Foundation
import HaloShared
import Supabase

enum AnalyticsEvent: String, Sendable {
  case signup
  case inviteSent = "invite_sent"
  case inviteAccepted = "invite_accepted"
  case vibeSet = "vibe_set"
  case momentCreated = "moment_created"
  case ringJoined = "ring_joined"
  case moveCloser = "move_closer"
}

@MainActor
final class AnalyticsService {
  static let shared = AnalyticsService()
  private init() {}

  private struct EventInsert: Encodable {
    let eventName: String
    let userId: UUID
    let targetUserId: UUID?
    let postId: UUID?
    let ringId: UUID?
    let inviteId: UUID?
    let tier: FriendshipTier?
    let metadata: [String: String]

    enum CodingKeys: String, CodingKey {
      case metadata, tier
      case eventName = "event_name"
      case userId = "user_id"
      case targetUserId = "target_user_id"
      case postId = "post_id"
      case ringId = "ring_id"
      case inviteId = "invite_id"
    }
  }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  func track(
    _ event: AnalyticsEvent,
    targetUserId: UUID? = nil,
    postId: UUID? = nil,
    ringId: UUID? = nil,
    inviteId: UUID? = nil,
    tier: FriendshipTier? = nil,
    metadata: [String: String] = [:]
  ) async {
    guard let userId = AuthService.shared.currentUserId() else { return }

    let row = EventInsert(
      eventName: event.rawValue,
      userId: userId,
      targetUserId: targetUserId,
      postId: postId,
      ringId: ringId,
      inviteId: inviteId,
      tier: tier,
      metadata: metadata
    )

    do {
      try await client
        .from("analytics_events")
        .insert(row)
        .execute()
    } catch {
      // Analytics must never block the core product action.
    }
  }
}
