import Foundation
import HaloShared
import Supabase

struct Campus: Codable, Identifiable, Hashable {
  let id: UUID
  let slug: String
  let name: String
  let emailDomain: String
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id, slug, name
    case emailDomain = "email_domain"
    case createdAt = "created_at"
  }
}

struct CampusVerification: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  let campusId: UUID
  let email: String
  let founderCode: String
  let verifiedAt: Date
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id, email
    case userId = "user_id"
    case campusId = "campus_id"
    case founderCode = "founder_code"
    case verifiedAt = "verified_at"
    case createdAt = "created_at"
  }
}

@MainActor
final class CampusVerificationService {
  static let shared = CampusVerificationService()
  private init() {}

  enum VerificationError: LocalizedError {
    case notAuthenticated
    case invalidEmail
    case campusNotFound

    var errorDescription: String? {
      switch self {
      case .notAuthenticated:
        return "Sessione non valida. Esci e rientra."
      case .invalidEmail:
        return "Usa la tua email @studbocconi.it."
      case .campusNotFound:
        return "Campus Bocconi non configurato."
      }
    }
  }

  private struct VerificationInsert: Encodable {
    let userId: UUID
    let campusId: UUID
    let email: String
    let founderCode: String

    enum CodingKeys: String, CodingKey {
      case email
      case userId = "user_id"
      case campusId = "campus_id"
      case founderCode = "founder_code"
    }
  }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  func bocconiCampus() async throws -> Campus {
    let rows: [Campus] = try await client
      .from("campuses")
      .select()
      .eq("slug", value: "bocconi")
      .limit(1)
      .execute()
      .value
    guard let campus = rows.first else {
      throw VerificationError.campusNotFound
    }
    return campus
  }

  func currentBocconiVerification() async throws -> CampusVerification? {
    guard let me = AuthService.shared.currentUserId() else {
      throw VerificationError.notAuthenticated
    }
    let campus = try await bocconiCampus()
    let rows: [CampusVerification] = try await client
      .from("campus_verifications")
      .select()
      .eq("user_id", value: me)
      .eq("campus_id", value: campus.id)
      .limit(1)
      .execute()
      .value
    return rows.first
  }

  @discardableResult
  func verifyBocconi(email: String, founderCode: String) async throws -> CampusVerification {
    guard let me = AuthService.shared.currentUserId() else {
      throw VerificationError.notAuthenticated
    }

    let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard normalizedEmail.hasSuffix("@studbocconi.it") else {
      throw VerificationError.invalidEmail
    }

    let campus = try await bocconiCampus()
    if let existing = try await currentBocconiVerification() {
      return existing
    }

    let row = VerificationInsert(
      userId: me,
      campusId: campus.id,
      email: normalizedEmail,
      founderCode: founderCode.trimmingCharacters(in: .whitespacesAndNewlines)
    )

    do {
      let saved: CampusVerification = try await client
        .from("campus_verifications")
        .insert(row)
        .select()
        .single()
        .execute()
        .value
      return saved
    } catch let error as PostgrestError where error.code == "23505" {
      if let existing = try await currentBocconiVerification() {
        return existing
      }
      throw error
    }
  }
}
