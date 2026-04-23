import Foundation
import HaloShared

@MainActor
final class StorageService {
  static let shared = StorageService()
  private init() {}

  enum StorageError: Error { case notImplemented }

  static let avatarsBucket = "halo-avatars"
  static let mediaBucket   = "halo-media"

  func uploadAvatar(data: Data, contentType: String) async throws -> String {
    throw StorageError.notImplemented // TODO step 5
  }

  func uploadPostMedia(data: Data, contentType: String) async throws -> String {
    throw StorageError.notImplemented // TODO step 6
  }

  func signedURL(forPath path: String, bucket: String, ttlSeconds: Int = 3600) async throws -> URL {
    throw StorageError.notImplemented
  }
}
