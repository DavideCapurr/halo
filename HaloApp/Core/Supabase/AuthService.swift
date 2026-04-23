import Foundation
import HaloShared

/// Step 4: Sign in with Apple + email OTP.
/// API pubblica stabile; implementazione interna userà `SupabaseClientProvider.shared.auth`.
@MainActor
final class AuthService {
  static let shared = AuthService()
  private init() {}

  enum AuthError: Error { case notImplemented, cancelled, invalidResponse }

  func signInWithApple() async throws -> Profile {
    throw AuthError.notImplemented // TODO step 4
  }

  func signOut() async throws {
    throw AuthError.notImplemented // TODO step 4
  }

  func currentUserId() -> UUID? {
    nil // TODO step 4: leggere da SupabaseClientProvider.shared.auth.session
  }
}
