import Foundation
import HaloShared
import Supabase

@MainActor
final class ProfilesService {
  static let shared = ProfilesService()
  private init() {}

  enum ProfilesError: LocalizedError {
    case notAuthenticated
    case notFound
    case handleTaken
    case saveFailed(message: String)

    var errorDescription: String? {
      switch self {
      case .notAuthenticated:
        return "Sessione non valida. Esci e rientra."
      case .notFound:
        return "Profilo non trovato."
      case .handleTaken:
        return "Questo handle e gia preso."
      case .saveFailed(let message):
        return message
      }
    }
  }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  func currentProfile() async throws -> Profile {
    guard let userId = AuthService.shared.currentUserId() else {
      throw ProfilesError.notAuthenticated
    }
    return try await profile(id: userId)
  }

  func profile(id: UUID) async throws -> Profile {
    let matches: [Profile] = try await client
      .from("profiles")
      .select()
      .eq("id", value: id)
      .limit(1)
      .execute()
      .value

    guard let profile = matches.first else {
      throw ProfilesError.notFound
    }
    return profile
  }

  /// Upsert sul profilo corrente. La policy RLS richiede `id = auth.uid()`.
  func update(_ profile: Profile) async throws {
    do {
      try await client
        .from("profiles")
        .upsert(profile)
        .execute()
    } catch let error as PostgrestError {
      if error.code == "23505" {
        throw ProfilesError.handleTaken
      }
      throw ProfilesError.saveFailed(message: error.detail ?? error.message)
    } catch {
      throw ProfilesError.saveFailed(message: error.localizedDescription)
    }
  }

  func isHandleAvailable(_ handle: String, excluding userId: UUID) async throws -> Bool {
    struct ProfileIdentity: Decodable {
      let id: UUID
    }

    let matches: [ProfileIdentity] = try await client
      .from("profiles")
      .select("id")
      .eq("handle", value: handle)
      .limit(1)
      .execute()
      .value

    guard let first = matches.first else { return true }
    return first.id == userId
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

  /// Discovery: account pubblici recenti, ordinati per `created_at` desc.
  /// Usato dalla pagina di esplorazione per agganciare celeb/brand/artist.
  func discoverPublic(limit: Int = 30) async throws -> [Profile] {
    try await client
      .from("profiles")
      .select()
      .eq("is_public", value: true)
      .order("created_at", ascending: false)
      .limit(limit)
      .execute()
      .value
  }

  /// Ricerca filtrata ai soli account pubblici.
  func searchPublic(handle prefix: String) async throws -> [Profile] {
    let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    return try await client
      .from("profiles")
      .select()
      .eq("is_public", value: true)
      .ilike("handle", pattern: "\(trimmed)%")
      .limit(20)
      .execute()
      .value
  }
}
