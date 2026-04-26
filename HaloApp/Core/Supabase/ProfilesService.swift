import Foundation
import HaloShared
import Supabase

@MainActor
final class ProfilesService {
  static let shared = ProfilesService()
  private init() {}

  enum ProfilesError: Error { case notAuthenticated, notFound }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  func currentProfile() async throws -> Profile {
    guard let userId = AuthService.shared.currentUserId() else {
      throw ProfilesError.notAuthenticated
    }
    return try await profile(id: userId)
  }

  func profile(id: UUID) async throws -> Profile {
    do {
      return try await client
        .from("profiles")
        .select()
        .eq("id", value: id)
        .single()
        .execute()
        .value
    } catch {
      throw ProfilesError.notFound
    }
  }

  /// Upsert sul profilo corrente. La policy RLS richiede `id = auth.uid()`.
  func update(_ profile: Profile) async throws {
    try await client
      .from("profiles")
      .upsert(profile)
      .execute()
  }

  /// Ricerca per prefisso di handle (case-insensitive grazie a `citext`).
  func search(handle prefix: String) async throws -> [Profile] {
    let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    return try await client
      .from("profiles")
      .select()
      .ilike("handle", pattern: "\(trimmed)%")
      .limit(20)
      .execute()
      .value
  }
}
