import Foundation
import HaloShared
import Supabase

@MainActor
final class VibesService {
  static let shared = VibesService()
  private init() {}

  enum VibesError: Error { case notAuthenticated }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  /// Inserisce una nuova vibe per l'utente corrente.
  /// Per mantenere una sola vibe attiva alla volta cancelliamo prima quelle ancora vive.
  @discardableResult
  func setCurrent(mood: Mood, colorHex: String, note: String?) async throws -> Vibe {
    guard let userId = AuthService.shared.currentUserId() else {
      throw VibesError.notAuthenticated
    }

    try await client
      .from("vibes")
      .delete()
      .eq("user_id", value: userId)
      .gt("expires_at", value: Date.now.iso8601String)
      .execute()

    let new = Vibe(userId: userId, mood: mood, colorHex: colorHex, note: note)
    let saved: Vibe = try await client
      .from("vibes")
      .insert(new)
      .select()
      .single()
      .execute()
      .value
    return saved
  }

  func current(for userId: UUID) async throws -> Vibe? {
    let rows: [Vibe] = try await client
      .from("vibes")
      .select()
      .eq("user_id", value: userId)
      .gt("expires_at", value: Date.now.iso8601String)
      .order("created_at", ascending: false)
      .limit(1)
      .execute()
      .value
    return rows.first
  }

  /// Bulk lookup per il feed/orbital: una sola query, mappata per user_id.
  func currentVibes(for userIds: [UUID]) async throws -> [UUID: Vibe] {
    guard !userIds.isEmpty else { return [:] }
    let rows: [Vibe] = try await client
      .from("vibes")
      .select()
      .in("user_id", values: userIds)
      .gt("expires_at", value: Date.now.iso8601String)
      .execute()
      .value
    return Dictionary(grouping: rows, by: \.userId).compactMapValues { vibes in
      vibes.max(by: { $0.createdAt < $1.createdAt })
    }
  }
}

private extension Date {
  /// Iso8601 con frazioni: tollerato sia da Postgrest sia dai timestamp con timezone.
  var iso8601String: String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.string(from: self)
  }
}
