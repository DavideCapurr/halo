import Foundation
import HaloShared
import Supabase

@MainActor
final class StorageService {
  static let shared = StorageService()
  private init() {}

  enum StorageError: Error { case notAuthenticated, invalidContentType }

  static let avatarsBucket = "halo-avatars"
  static let mediaBucket   = "halo-media"

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  /// Carica l'avatar dell'utente corrente. Path: `<user_id>/<uuid>.<ext>`.
  /// Restituisce il path (non la URL): la URL firmata si chiede a `signedURL`.
  func uploadAvatar(data: Data, contentType: String) async throws -> String {
    try await upload(data: data, contentType: contentType, bucket: Self.avatarsBucket)
  }

  func uploadPostMedia(data: Data, contentType: String) async throws -> String {
    try await upload(data: data, contentType: contentType, bucket: Self.mediaBucket)
  }

  func signedURL(forPath path: String, bucket: String, ttlSeconds: Int = 3600) async throws -> URL {
    try await client.storage
      .from(bucket)
      .createSignedURL(path: path, expiresIn: ttlSeconds)
  }

  // MARK: - Internals

  private func upload(data: Data, contentType: String, bucket: String) async throws -> String {
    guard let userId = AuthService.shared.currentUserId() else {
      throw StorageError.notAuthenticated
    }
    let ext = Self.fileExtension(for: contentType)
    let path = "\(userId.uuidString.lowercased())/\(UUID().uuidString.lowercased()).\(ext)"
    _ = try await client.storage
      .from(bucket)
      .upload(
        path,
        data: data,
        options: FileOptions(contentType: contentType, upsert: false)
      )
    return path
  }

  private static func fileExtension(for contentType: String) -> String {
    switch contentType.lowercased() {
    case "image/jpeg", "image/jpg": return "jpg"
    case "image/png":               return "png"
    case "image/heic":              return "heic"
    case "image/webp":              return "webp"
    case "audio/m4a", "audio/mp4":  return "m4a"
    case "audio/aac":               return "aac"
    case "audio/wav":               return "wav"
    default:                        return "bin"
    }
  }
}
