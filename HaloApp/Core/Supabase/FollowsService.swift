import Foundation
import HaloShared
import Supabase

@MainActor
final class FollowsService {
  static let shared = FollowsService()
  private init() {}

  enum FollowsError: Error { case notAuthenticated, promotionRequiresConfirmation }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  /// Crea una follow di default a `nebula`. Tier superiori richiedono proposta+conferma
  /// (lo enforce il trigger `follows_tier_promotion_guard` lato DB).
  @discardableResult
  func follow(_ userId: UUID) async throws -> Follow {
    guard let me = AuthService.shared.currentUserId() else {
      throw FollowsError.notAuthenticated
    }
    let row = Follow(followerId: me, followeeId: userId, tier: .nebula)
    let saved: Follow = try await client
      .from("follows")
      .insert(row)
      .select()
      .single()
      .execute()
      .value
    return saved
  }

  func unfollow(_ userId: UUID) async throws {
    guard let me = AuthService.shared.currentUserId() else {
      throw FollowsError.notAuthenticated
    }
    try await client
      .from("follows")
      .delete()
      .eq("follower_id", value: me)
      .eq("followee_id", value: userId)
      .execute()
  }

  /// Drag-to-tier. Chi propone setta `proposed_tier` + `proposed_by`.
  /// La controparte conferma via `acceptProposedTier` aggiornando `tier`.
  func proposeTier(_ tier: FriendshipTier, for followeeId: UUID) async throws {
    guard let me = AuthService.shared.currentUserId() else {
      throw FollowsError.notAuthenticated
    }
    try await client
      .from("follows")
      .update([
        "proposed_tier": tier.rawValue,
        "proposed_by": me.uuidString.lowercased()
      ])
      .eq("follower_id", value: me)
      .eq("followee_id", value: followeeId)
      .execute()
  }

  /// La controparte (followee) conferma la proposta del follower applicandola a `tier`.
  /// Il trigger lato DB azzera `proposed_*` e verifica che chi conferma sia diverso da chi ha proposto.
  func acceptProposedTier(on followerId: UUID) async throws {
    guard let me = AuthService.shared.currentUserId() else {
      throw FollowsError.notAuthenticated
    }
    let row: Follow = try await client
      .from("follows")
      .select()
      .eq("follower_id", value: followerId)
      .eq("followee_id", value: me)
      .single()
      .execute()
      .value
    guard let proposed = row.proposedTier else {
      throw FollowsError.promotionRequiresConfirmation
    }
    try await client
      .from("follows")
      .update(["tier": proposed.rawValue])
      .eq("follower_id", value: followerId)
      .eq("followee_id", value: me)
      .execute()
  }

  func declineProposedTier(on followerId: UUID) async throws {
    guard let me = AuthService.shared.currentUserId() else {
      throw FollowsError.notAuthenticated
    }
    try await client
      .from("follows")
      .update([
        "proposed_tier": nil as String?,
        "proposed_by": nil as String?
      ])
      .eq("follower_id", value: followerId)
      .eq("followee_id", value: me)
      .execute()
  }

  /// Le follow del viewer corrente (chi seguo, con quale tier).
  func myFollows() async throws -> [Follow] {
    guard let me = AuthService.shared.currentUserId() else { return [] }
    return try await client
      .from("follows")
      .select()
      .eq("follower_id", value: me)
      .execute()
      .value
  }

  /// Vero quando l'utente ha gia almeno un Inner confermato o una proposta
  /// Inner pendente. Per il cold start basta che il Choose-your-5 sia partito.
  func hasStartedInnerCircle() async throws -> Bool {
    let follows = try await myFollows()
    return follows.contains { follow in
      follow.tier == .inner || follow.proposedTier == .inner
    }
  }

  /// Usa la semantica onboarding: crea la follow se manca e propone Inner.
  /// Se la follow esiste gia, la proposta resta comunque l'operazione utile.
  func addInitialInnerCandidate(_ userId: UUID) async throws {
    do {
      _ = try await follow(userId)
    } catch {
      // Una follow esistente e accettabile: aggiorniamo comunque la proposta.
    }
    try await proposeTier(.inner, for: userId)
  }

  /// Vero se esiste una follow nei due versi tra il viewer e `userId`.
  /// Usato dall'orbital field per separare bolle "vere" dagli asteroidi.
  func isMutual(with userId: UUID) async throws -> Bool {
    guard let me = AuthService.shared.currentUserId() else { return false }
    let rows: [Follow] = try await client
      .from("follows")
      .select()
      .or("and(follower_id.eq.\(me.uuidString.lowercased()),followee_id.eq.\(userId.uuidString.lowercased())),and(follower_id.eq.\(userId.uuidString.lowercased()),followee_id.eq.\(me.uuidString.lowercased()))")
      .execute()
      .value
    return rows.count >= 2
  }

  /// Versione bulk: per ognuno degli userIds dice se è mutuale col viewer.
  /// Più efficiente in feed/orbital che chiamare `isMutual` in loop.
  func mutualSet(among userIds: [UUID]) async throws -> Set<UUID> {
    guard let me = AuthService.shared.currentUserId(), !userIds.isEmpty else { return [] }
    async let outgoing: [Follow] = client
      .from("follows")
      .select()
      .eq("follower_id", value: me)
      .in("followee_id", values: userIds)
      .execute()
      .value
    async let incoming: [Follow] = client
      .from("follows")
      .select()
      .eq("followee_id", value: me)
      .in("follower_id", values: userIds)
      .execute()
      .value
    let out = Set(try await outgoing.map(\.followeeId))
    let inc = Set(try await incoming.map(\.followerId))
    return out.intersection(inc)
  }
}
