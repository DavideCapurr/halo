import Foundation
import HaloShared
import Supabase

/// Penny campaigns service. Mirrors `RingsService`: thin async wrappers over the
/// Supabase tables + RPCs created in `20260608120000_penny_campaigns.sql`.
///
/// Money never flows through here. Donations (the `paid` state and platform fee)
/// are written by the Stripe webhook with the service role; this client only
/// reads campaigns/contributions and creates campaigns. The Stripe Connect +
/// PaymentSheet wiring lands in a later phase.
@MainActor
final class CampaignsService {
  static let shared = CampaignsService()
  private init() {}

  enum CampaignsError: LocalizedError {
    case notAuthenticated
    case invalidTitle
    case invalidGoal

    var errorDescription: String? {
      switch self {
      case .notAuthenticated:
        return "Sessione non valida. Esci e rientra."
      case .invalidTitle:
        return "Dai un nome alla campagna."
      case .invalidGoal:
        return "Imposta un obiettivo maggiore di zero."
      }
    }
  }

  private struct CampaignInsert: Encodable {
    let creatorId: UUID
    let title: String
    let description: String?
    let goalCents: Int
    let currency: String
    let minTier: FriendshipTier
    let isPublic: Bool
    let status: CampaignStatus
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
      case title, description, currency, status
      case creatorId = "creator_id"
      case goalCents = "goal_cents"
      case minTier = "min_tier"
      case isPublic = "is_public"
      case expiresAt = "expires_at"
    }
  }

  private struct StatusUpdate: Encodable {
    let status: CampaignStatus
  }

  private struct SlugParams: Encodable {
    let slug: String

    enum CodingKeys: String, CodingKey {
      case slug = "p_slug"
    }
  }

  /// Stripe Connect onboarding status for the current creator.
  struct ConnectStatus: Codable, Sendable {
    let stripeAccountId: String
    let chargesEnabled: Bool
    let payoutsEnabled: Bool
    let detailsSubmitted: Bool

    enum CodingKeys: String, CodingKey {
      case stripeAccountId = "stripe_account_id"
      case chargesEnabled = "charges_enabled"
      case payoutsEnabled = "payouts_enabled"
      case detailsSubmitted = "details_submitted"
    }
  }

  /// Everything PaymentSheet needs for a direct-charge donation.
  struct PaymentParams: Decodable, Sendable {
    let clientSecret: String
    let publishableKey: String
    let connectedAccountId: String
    let paymentIntentId: String
  }

  private struct OnboardResponse: Decodable { let url: URL }

  private struct PaymentRequestBody: Encodable {
    let campaignId: UUID
    let amountCents: Int
    let displayName: String?
    let message: String?
    let isAnonymous: Bool
    let idempotencyKey: String
  }

  private var client: SupabaseClient { SupabaseClientProvider.shared }

  /// Campaigns created by the current user.
  func myCampaigns() async throws -> [Campaign] {
    guard let me = AuthService.shared.currentUserId() else {
      throw CampaignsError.notAuthenticated
    }
    return try await client
      .from("campaigns")
      .select()
      .eq("creator_id", value: me)
      .order("created_at", ascending: false)
      .execute()
      .value
  }

  /// Public, non-draft campaigns for discovery.
  func publicCampaigns() async throws -> [Campaign] {
    try await client
      .from("campaigns")
      .select()
      .eq("is_public", value: true)
      .neq("status", value: CampaignStatus.draft.rawValue)
      .order("created_at", ascending: false)
      .execute()
      .value
  }

  func campaign(id: UUID) async throws -> Campaign {
    try await client
      .from("campaigns")
      .select()
      .eq("id", value: id)
      .single()
      .execute()
      .value
  }

  /// Anon-safe lookup by public slug (used by the contribute deep link and the
  /// public landing). Returns nil when the slug is unknown / private / draft.
  func publicCampaign(slug: String) async throws -> PublicCampaign? {
    let clean = normalizeSlug(slug)
    guard !clean.isEmpty else { return nil }
    let rows: [PublicCampaign] = try await client
      .rpc("public_campaign_by_slug", params: SlugParams(slug: clean))
      .execute()
      .value
    return rows.first
  }

  func publicSupporters(slug: String) async throws -> [PublicSupporter] {
    let clean = normalizeSlug(slug)
    guard !clean.isEmpty else { return [] }
    return try await client
      .rpc("public_campaign_supporters", params: SlugParams(slug: clean))
      .execute()
      .value
  }

  func contributions(for campaignId: UUID) async throws -> [CampaignContribution] {
    try await client
      .from("campaign_contributions")
      .select()
      .eq("campaign_id", value: campaignId)
      .order("created_at", ascending: false)
      .execute()
      .value
  }

  @discardableResult
  func create(
    title: String,
    description: String? = nil,
    goalCents: Int,
    currency: String = "eur",
    minTier: FriendshipTier = .nebula,
    isPublic: Bool = true,
    expiresAt: Date? = nil
  ) async throws -> Campaign {
    guard let me = AuthService.shared.currentUserId() else {
      throw CampaignsError.notAuthenticated
    }

    let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard cleanTitle.count >= 2 else { throw CampaignsError.invalidTitle }
    guard goalCents > 0 else { throw CampaignsError.invalidGoal }

    let row = CampaignInsert(
      creatorId: me,
      title: cleanTitle,
      description: cleanOptional(description),
      goalCents: goalCents,
      currency: currency.lowercased(),
      // min_tier maps to the DB friendship_tier enum (nebula/orbit/close/inner).
      minTier: minTier == .asteroid ? .nebula : minTier,
      isPublic: isPublic,
      status: .active,
      expiresAt: expiresAt
    )

    return try await client
      .from("campaigns")
      .insert(row)
      .select()
      .single()
      .execute()
      .value
  }

  @discardableResult
  func setStatus(_ status: CampaignStatus, campaignId: UUID) async throws -> Campaign {
    try await client
      .from("campaigns")
      .update(StatusUpdate(status: status))
      .eq("id", value: campaignId)
      .select()
      .single()
      .execute()
      .value
  }

  // MARK: - Stripe Connect + payments

  /// Connect onboarding status for the current user, or nil if never started.
  func connectStatus() async throws -> ConnectStatus? {
    guard let me = AuthService.shared.currentUserId() else { return nil }
    let rows: [ConnectStatus] = try await client
      .from("stripe_accounts")
      .select("stripe_account_id, charges_enabled, payouts_enabled, details_submitted")
      .eq("user_id", value: me)
      .limit(1)
      .execute()
      .value
    return rows.first
  }

  /// Creates/reuses the creator's connected account and returns the Stripe-hosted
  /// onboarding URL to open in a browser.
  func startConnectOnboarding() async throws -> URL {
    let resp: OnboardResponse = try await client.functions.invoke(
      "campaign-connect-onboard",
      options: FunctionInvokeOptions()
    )
    return resp.url
  }

  /// Creates a PaymentIntent (direct charge on the creator's account, with Halo's
  /// application fee) and a pending contribution. Returns PaymentSheet params.
  func createPaymentIntent(
    campaignId: UUID,
    amountCents: Int,
    displayName: String?,
    message: String?,
    isAnonymous: Bool
  ) async throws -> PaymentParams {
    let body = PaymentRequestBody(
      campaignId: campaignId,
      amountCents: amountCents,
      displayName: displayName,
      message: cleanOptional(message),
      isAnonymous: isAnonymous,
      idempotencyKey: UUID().uuidString
    )
    return try await client.functions.invoke(
      "campaign-create-payment",
      options: FunctionInvokeOptions(body: body)
    )
  }

  private func cleanOptional(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed?.isEmpty == true ? nil : trimmed
  }

  private func normalizeSlug(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if let url = URL(string: trimmed),
       let link = DeepLink(url: url),
       case .campaignContribute(let slug) = link {
      return slug
    }
    return trimmed
      .replacingOccurrences(of: "halo://campaign/c/", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
