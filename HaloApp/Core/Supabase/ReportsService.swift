import Foundation
import HaloShared
import Supabase

enum ReportReason: String, Codable, CaseIterable, Identifiable {
  case harassment
  case spam
  case impersonation
  case unsafe
  case other

  var id: String { rawValue }

  var label: String {
    switch self {
    case .harassment: return "molestie"
    case .spam: return "spam"
    case .impersonation: return "identita falsa"
    case .unsafe: return "non mi sento al sicuro"
    case .other: return "altro"
    }
  }
}

struct SafetyReport: Codable, Identifiable, Hashable {
  let id: UUID
  let reporterId: UUID
  let reportedUserId: UUID
  let postId: UUID?
  let reason: ReportReason
  let details: String?
  let status: String
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id, reason, details, status
    case reporterId = "reporter_id"
    case reportedUserId = "reported_user_id"
    case postId = "post_id"
    case createdAt = "created_at"
  }
}

@MainActor
final class ReportsService {
  static let shared = ReportsService()
  private init() {}

  enum SafetyError: LocalizedError {
    case notAuthenticated
    case invalidTarget

    var errorDescription: String? {
      switch self {
      case .notAuthenticated:
        return "Sessione non valida. Esci e rientra."
      case .invalidTarget:
        return "Non puoi segnalare questo profilo."
      }
    }
  }

  private struct ReportInsert: Encodable {
    let reporterId: UUID
    let reportedUserId: UUID
    let postId: UUID?
    let reason: ReportReason
    let details: String?

    enum CodingKeys: String, CodingKey {
      case reason, details
      case reporterId = "reporter_id"
      case reportedUserId = "reported_user_id"
      case postId = "post_id"
    }
  }

  private struct BlockRow: Codable, Hashable {
    let blockerId: UUID
    let blockedUserId: UUID

    enum CodingKeys: String, CodingKey {
      case blockerId = "blocker_id"
      case blockedUserId = "blocked_user_id"
    }
  }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  @discardableResult
  func submit(
    reportedUserId: UUID,
    postId: UUID? = nil,
    reason: ReportReason,
    details: String?
  ) async throws -> SafetyReport {
    guard let me = AuthService.shared.currentUserId() else {
      throw SafetyError.notAuthenticated
    }
    guard me != reportedUserId else {
      throw SafetyError.invalidTarget
    }

    let trimmed = details?.trimmingCharacters(in: .whitespacesAndNewlines)
    let row = ReportInsert(
      reporterId: me,
      reportedUserId: reportedUserId,
      postId: postId,
      reason: reason,
      details: trimmed?.isEmpty == true ? nil : trimmed
    )

    let saved: SafetyReport = try await client
      .from("reports")
      .insert(row)
      .select()
      .single()
      .execute()
      .value
    return saved
  }

  func block(_ userId: UUID) async throws {
    guard let me = AuthService.shared.currentUserId() else {
      throw SafetyError.notAuthenticated
    }
    guard me != userId else {
      throw SafetyError.invalidTarget
    }

    try await client
      .from("blocks")
      .upsert(BlockRow(blockerId: me, blockedUserId: userId))
      .execute()

    try? await FollowsService.shared.unfollow(userId)
  }

  func unblock(_ userId: UUID) async throws {
    guard let me = AuthService.shared.currentUserId() else {
      throw SafetyError.notAuthenticated
    }
    try await client
      .from("blocks")
      .delete()
      .eq("blocker_id", value: me)
      .eq("blocked_user_id", value: userId)
      .execute()
  }

  func blockedIds() async throws -> Set<UUID> {
    guard let me = AuthService.shared.currentUserId() else { return [] }
    let rows: [BlockRow] = try await client
      .from("blocks")
      .select()
      .eq("blocker_id", value: me)
      .execute()
      .value
    return Set(rows.map(\.blockedUserId))
  }
}
