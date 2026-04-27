import Foundation
import AuthenticationServices
import HaloShared
import Supabase

/// Sign in with Apple + email OTP. Espone session tracking sincrono via `currentUserId()`.
@MainActor
final class AuthService {
  static let shared = AuthService()
  private init() {}

  enum AuthError: Error { case cancelled, invalidResponse, missingProfile }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  /// Completa il flusso `SignInWithAppleButton`: prende l'`ASAuthorization`, estrae l'identityToken
  /// e fa lo scambio con Supabase. Restituisce il `Profile` corrente (creandolo se mancante).
  func signInWithApple(authorization: ASAuthorization, nonce: String) async throws -> Profile {
    guard
      let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
      let tokenData = credential.identityToken,
      let idToken = String(data: tokenData, encoding: .utf8)
    else {
      throw AuthError.invalidResponse
    }

    _ = try await client.auth.signInWithIdToken(
      credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
    )

    // Crea il profilo se è il primo login; in caso contrario lo carica.
    if let existing = try? await ProfilesService.shared.currentProfile() {
      return existing
    }
    let userId = try requireUserId()
    let suggestedHandle = bootstrapHandle(from: credential)
    let suggestedName = bootstrapDisplayName(from: credential)
    let new = Profile(id: userId, handle: suggestedHandle, displayName: suggestedName)
    try await ProfilesService.shared.update(new)
    return new
  }

  func signOut() async throws {
    try await client.auth.signOut()
  }

  func currentUserId() -> UUID? {
    client.auth.currentUser?.id
  }

  func requireUserId() throws -> UUID {
    guard let id = currentUserId() else { throw AuthError.cancelled }
    return id
  }

  // MARK: - Email OTP

  /// Manda un codice OTP via email (magic link disabled, solo OTP a 6 cifre).
  func requestEmailOTP(email: String) async throws {
    try await client.auth.signInWithOTP(email: email, shouldCreateUser: true)
  }

  /// Verifica il codice OTP e ritorna (creandolo se manca) il profilo dell'utente.
  func verifyEmailOTP(email: String, code: String) async throws -> Profile {
    _ = try await client.auth.verifyOTP(email: email, token: code, type: .email)
    if let existing = try? await ProfilesService.shared.currentProfile() {
      return existing
    }
    let userId = try requireUserId()
    let local = email.split(separator: "@").first.map(String.init) ?? "halo"
    let new = Profile(id: userId, handle: sanitizeHandle(local), displayName: "Halo")
    try await ProfilesService.shared.update(new)
    return new
  }

  // MARK: - Bootstrap helpers

  private func bootstrapHandle(from credential: ASAuthorizationAppleIDCredential) -> String {
    if let email = credential.email, let local = email.split(separator: "@").first {
      return sanitizeHandle(String(local))
    }
    return "halo_\(UUID().uuidString.prefix(6).lowercased())"
  }

  private func bootstrapDisplayName(from credential: ASAuthorizationAppleIDCredential) -> String {
    if let name = credential.fullName,
       let given = name.givenName, !given.isEmpty {
      if let family = name.familyName, !family.isEmpty {
        return "\(given) \(family)"
      }
      return given
    }
    return "Halo"
  }

  private func sanitizeHandle(_ raw: String) -> String {
    let lower = raw.lowercased()
    let allowed = lower.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == "_" || $0 == "." }
    let cleaned = String(String.UnicodeScalarView(allowed))
    return cleaned.isEmpty ? "halo_\(UUID().uuidString.prefix(6).lowercased())" : cleaned
  }
}
