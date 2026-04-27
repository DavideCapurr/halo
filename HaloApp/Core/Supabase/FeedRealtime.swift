import Foundation
import HaloShared
import Supabase

/// Subscribe ai cambi sul feed (post nuovi, vibe nuove, reazioni nuove).
/// Wrapper sottile sui realtime channels v2 di supabase-swift, con un'API
/// `AsyncStream` consumabile dal `FeedViewModel`.
@MainActor
final class FeedRealtime {
  enum Event: Sendable {
    case newPost(HaloPost)
    case newVibe(Vibe)
    case newReaction(Reaction)
  }

  private var channel: RealtimeChannelV2?
  private var continuations: [UUID: AsyncStream<Event>.Continuation] = [:]
  private var observerTask: Task<Void, Never>?

  /// AsyncStream a cui sottoscriversi per ricevere eventi del feed.
  /// L'eliminazione del consumer chiude implicitamente il continuation.
  func subscribe() -> AsyncStream<Event> {
    let key = UUID()
    return AsyncStream { continuation in
      self.continuations[key] = continuation
      continuation.onTermination = { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.continuations.removeValue(forKey: key)
        }
      }
      Task { @MainActor in
        await self.ensureChannel()
      }
    }
  }

  func disconnect() async {
    observerTask?.cancel()
    observerTask = nil
    if let channel {
      await channel.unsubscribe()
    }
    channel = nil
    for (_, c) in continuations { c.finish() }
    continuations.removeAll()
  }

  // MARK: - private

  private func ensureChannel() async {
    guard channel == nil else { return }
    let client = SupabaseClientProvider.shared
    let ch = client.channel("public:halo-feed")

    let postsInsert = ch.postgresChange(InsertAction.self, schema: "public", table: "halo_posts")
    let vibesInsert = ch.postgresChange(InsertAction.self, schema: "public", table: "vibes")
    let reactionsInsert = ch.postgresChange(InsertAction.self, schema: "public", table: "reactions")

    do {
      try await ch.subscribeWithError()
    } catch {
      self.channel = nil
      return
    }

    self.channel = ch

    self.observerTask = Task { [weak self] in
      await withTaskGroup(of: Void.self) { group in
        group.addTask { [weak self] in
          let decoder = Self.makeDecoder()
          for await change in postsInsert {
            if let post: HaloPost = try? change.decodeRecord(decoder: decoder) {
              await self?.broadcast(.newPost(post))
            }
          }
        }
        group.addTask { [weak self] in
          let decoder = Self.makeDecoder()
          for await change in vibesInsert {
            if let vibe: Vibe = try? change.decodeRecord(decoder: decoder) {
              await self?.broadcast(.newVibe(vibe))
            }
          }
        }
        group.addTask { [weak self] in
          let decoder = Self.makeDecoder()
          for await change in reactionsInsert {
            if let r: Reaction = try? change.decodeRecord(decoder: decoder) {
              await self?.broadcast(.newReaction(r))
            }
          }
        }
      }
    }
  }

  private func broadcast(_ event: Event) {
    for (_, c) in continuations { c.yield(event) }
  }

  /// Decoder configurato per i timestamps `timestamptz` di Postgres.
  private nonisolated static func makeDecoder() -> JSONDecoder {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .custom { dec in
      let s = try dec.singleValueContainer().decode(String.self)
      let fractional = ISO8601DateFormatter()
      fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = fractional.date(from: s) { return date }
      let plain = ISO8601DateFormatter()
      plain.formatOptions = [.withInternetDateTime]
      if let date = plain.date(from: s) { return date }
      throw DecodingError.dataCorruptedError(in: try dec.singleValueContainer(),
                                             debugDescription: "Invalid date: \(s)")
    }
    return d
  }
}
