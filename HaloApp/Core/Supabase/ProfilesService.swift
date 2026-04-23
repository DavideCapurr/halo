import Foundation
import HaloShared

@MainActor
final class ProfilesService {
  static let shared = ProfilesService()
  private init() {}

  enum ProfilesError: Error { case notImplemented, notFound }

  func currentProfile() async throws -> Profile {
    throw ProfilesError.notImplemented // TODO step 5
  }

  func update(_ profile: Profile) async throws {
    throw ProfilesError.notImplemented // TODO step 5
  }

  func search(handle prefix: String) async throws -> [Profile] {
    throw ProfilesError.notImplemented // TODO step 7
  }

  func profile(id: UUID) async throws -> Profile {
    throw ProfilesError.notImplemented // TODO step 5
  }
}
