import Foundation
import HaloShared

@MainActor
final class VibesService {
  static let shared = VibesService()
  private init() {}

  enum VibesError: Error { case notImplemented }

  func setCurrent(mood: Mood, colorHex: String, note: String?) async throws -> Vibe {
    throw VibesError.notImplemented // TODO step 5
  }

  func current(for userId: UUID) async throws -> Vibe? {
    throw VibesError.notImplemented // TODO step 5
  }

  func currentVibes(for userIds: [UUID]) async throws -> [UUID: Vibe] {
    throw VibesError.notImplemented // TODO step 8 (usato da HomeViewModel)
  }
}
