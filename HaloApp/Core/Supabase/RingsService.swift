import Foundation
import HaloShared
import Supabase

@MainActor
final class RingsService {
  static let shared = RingsService()
  private init() {}

  enum RingsError: LocalizedError {
    case notAuthenticated
    case invalidTitle
    case invalidToken

    var errorDescription: String? {
      switch self {
      case .notAuthenticated:
        return "Sessione non valida. Esci e rientra."
      case .invalidTitle:
        return "Dai un nome al ring."
      case .invalidToken:
        return "Token ring non valido."
      }
    }
  }

  private struct RingInsert: Encodable {
    let kind: RingKind
    let creatorId: UUID
    let title: String
    let subtitle: String?
    let locationName: String?
    let startsAt: Date?
    let endsAt: Date?
    let expiresAt: Date?
    let isPublic: Bool
    let requiresApproval: Bool
    let memberLimit: Int?
    let priceCents: Int?
    let currency: String

    enum CodingKeys: String, CodingKey {
      case kind, title, subtitle, currency
      case creatorId = "creator_id"
      case locationName = "location_name"
      case startsAt = "starts_at"
      case endsAt = "ends_at"
      case expiresAt = "expires_at"
      case isPublic = "is_public"
      case requiresApproval = "requires_approval"
      case memberLimit = "member_limit"
      case priceCents = "price_cents"
    }
  }

  private struct TokenParams: Encodable {
    let token: String

    enum CodingKeys: String, CodingKey {
      case token = "p_token"
    }
  }

  private struct RingIdParams: Encodable {
    let ringId: UUID

    enum CodingKeys: String, CodingKey {
      case ringId = "p_ring_id"
    }
  }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  func rings(kind: RingKind? = nil) async throws -> [HaloRing] {
    if let kind {
      return try await client
        .from("rings")
        .select()
        .eq("kind", value: kind.rawValue)
        .order("created_at", ascending: false)
        .execute()
        .value
    }

    return try await client
      .from("rings")
      .select()
      .order("created_at", ascending: false)
      .execute()
      .value
  }

  func ring(id: UUID) async throws -> HaloRing {
    try await client
      .from("rings")
      .select()
      .eq("id", value: id)
      .single()
      .execute()
      .value
  }

  @discardableResult
  func create(
    kind: RingKind,
    title: String,
    subtitle: String? = nil,
    locationName: String? = nil,
    startsAt: Date? = nil,
    endsAt: Date? = nil,
    isPublic: Bool = false,
    requiresApproval: Bool = false,
    memberLimit: Int? = nil,
    priceCents: Int? = nil,
    currency: String = "eur"
  ) async throws -> HaloRing {
    guard let me = AuthService.shared.currentUserId() else {
      throw RingsError.notAuthenticated
    }

    let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard cleanTitle.count >= 2 else {
      throw RingsError.invalidTitle
    }

    let cleanSubtitle = cleanOptional(subtitle)
    let cleanLocation = cleanOptional(locationName)
    let expiresAt = expirationDate(kind: kind, startsAt: startsAt, endsAt: endsAt)
    let row = RingInsert(
      kind: kind,
      creatorId: me,
      title: cleanTitle,
      subtitle: cleanSubtitle,
      locationName: cleanLocation,
      startsAt: startsAt,
      endsAt: endsAt,
      expiresAt: expiresAt,
      isPublic: isPublic,
      requiresApproval: requiresApproval,
      memberLimit: memberLimit,
      priceCents: kind == .club || kind == .course ? priceCents : nil,
      currency: currency.lowercased()
    )

    let saved: HaloRing = try await client
      .from("rings")
      .insert(row)
      .select()
      .single()
      .execute()
      .value
    return saved
  }

  @discardableResult
  func join(token rawToken: String) async throws -> HaloRing {
    let token = normalizeToken(rawToken)
    guard !token.isEmpty else { throw RingsError.invalidToken }

    return try await client
      .rpc("join_ring_by_token", params: TokenParams(token: token))
      .single()
      .execute()
      .value
  }

  @discardableResult
  func joinPublic(ringId: UUID) async throws -> HaloRing {
    try await client
      .rpc("join_public_ring", params: RingIdParams(ringId: ringId))
      .single()
      .execute()
      .value
  }

  @discardableResult
  func refreshJoinToken(ringId: UUID) async throws -> HaloRing {
    try await client
      .rpc("refresh_ring_join_token", params: RingIdParams(ringId: ringId))
      .single()
      .execute()
      .value
  }

  @discardableResult
  func checkIn(eventRingId: UUID) async throws -> EventCheckIn {
    try await client
      .rpc("check_in_event_ring", params: RingIdParams(ringId: eventRingId))
      .single()
      .execute()
      .value
  }

  func members(for ringId: UUID) async throws -> [RingMember] {
    try await client
      .from("ring_members")
      .select()
      .eq("ring_id", value: ringId)
      .order("joined_at", ascending: false)
      .execute()
      .value
  }

  func checkIns(for ringId: UUID) async throws -> [EventCheckIn] {
    try await client
      .from("event_checkins")
      .select()
      .eq("ring_id", value: ringId)
      .order("checked_in_at", ascending: false)
      .execute()
      .value
  }

  func subscriptions(for ringId: UUID) async throws -> [RingSubscription] {
    try await client
      .from("subscriptions")
      .select()
      .eq("ring_id", value: ringId)
      .order("created_at", ascending: false)
      .execute()
      .value
  }

  func billing(for ringId: UUID) async throws -> [ClubBilling] {
    try await client
      .from("club_billing")
      .select()
      .eq("ring_id", value: ringId)
      .order("created_at", ascending: false)
      .execute()
      .value
  }

  private func cleanOptional(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed?.isEmpty == true ? nil : trimmed
  }

  private func normalizeToken(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

    if let url = URL(string: trimmed),
       let link = DeepLink(url: url),
       case .ringJoin(let token) = link {
      return token
    }

    return trimmed
      .replacingOccurrences(of: "halo://ring/join/", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func expirationDate(kind: RingKind, startsAt: Date?, endsAt: Date?) -> Date? {
    switch kind {
    case .event:
      return (endsAt ?? startsAt)?.addingTimeInterval(12 * 60 * 60)
    case .course:
      return endsAt
    case .club, .founder:
      return nil
    }
  }
}
