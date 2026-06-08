import Foundation

/// Lifecycle of a penny campaign. `goal_cents` is a milestone, not a cap: a
/// campaign keeps accepting donations past 100% and only leaves `active` when the
/// creator closes it or it expires.
public enum CampaignStatus: String, Codable, CaseIterable, Identifiable, Sendable {
  case draft
  case active
  case closed

  public var id: String { rawValue }
}

public enum CampaignContributionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
  case pending
  case paid
  case failed
  case refunded

  public var id: String { rawValue }
}

/// A Mike Hayes-style campaign: a goal reached through many small real donations
/// that propagate through the Halo graph (via `minTier`) and a public web link.
/// Funds never touch Halo — they flow donor -> creator through Stripe Connect.
public struct Campaign: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public let creatorId: UUID
  public var title: String
  public var description: String?
  public var coverPath: String?
  public var goalCents: Int
  public var currency: String
  public var raisedCents: Int
  public var supporterCount: Int
  /// In-Halo reach: tier the viewer must reach to see the campaign. `.nebula`
  /// (default) means everyone who follows the creator, public follows included.
  public var minTier: FriendshipTier
  public var isPublic: Bool
  public var status: CampaignStatus
  public let publicSlug: String
  public var joinToken: String
  public var stripeAccountId: String?
  public let createdAt: Date
  public let updatedAt: Date
  public var expiresAt: Date?

  /// Progress toward the goal, clamped 0...1 for bar rendering. Use
  /// `rawProgress` when you need to show overfunding past 100%.
  public var progress: Double {
    min(max(rawProgress, 0), 1)
  }

  public var rawProgress: Double {
    guard goalCents > 0 else { return 0 }
    return Double(raisedCents) / Double(goalCents)
  }

  public var hasReachedGoal: Bool {
    raisedCents >= goalCents
  }

  public var isExpired: Bool {
    guard let expiresAt else { return false }
    return expiresAt <= .now
  }

  public var isCollecting: Bool {
    status == .active && !isExpired
  }

  /// Deep link to the campaign inside the Halo app.
  public var deepLink: URL? {
    DeepLink.campaign(id: id).url
  }

  /// Deep link that opens the contribute flow by public slug.
  public var contributeDeepLink: URL? {
    DeepLink.campaignContribute(slug: publicSlug).url
  }

  /// Public web URL for sharing outside Halo (true Mike Hayes reach).
  /// `base` is the deployed landing host, e.g. `https://halo.app`.
  public func webShareURL(base: URL) -> URL {
    base.appendingPathComponent("c").appendingPathComponent(publicSlug)
  }

  public init(
    id: UUID = UUID(),
    creatorId: UUID,
    title: String,
    description: String? = nil,
    coverPath: String? = nil,
    goalCents: Int,
    currency: String = "eur",
    raisedCents: Int = 0,
    supporterCount: Int = 0,
    minTier: FriendshipTier = .nebula,
    isPublic: Bool = true,
    status: CampaignStatus = .active,
    publicSlug: String = "",
    joinToken: String = "",
    stripeAccountId: String? = nil,
    createdAt: Date = .now,
    updatedAt: Date = .now,
    expiresAt: Date? = nil
  ) {
    self.id = id
    self.creatorId = creatorId
    self.title = title
    self.description = description
    self.coverPath = coverPath
    self.goalCents = goalCents
    self.currency = currency
    self.raisedCents = raisedCents
    self.supporterCount = supporterCount
    self.minTier = minTier
    self.isPublic = isPublic
    self.status = status
    self.publicSlug = publicSlug
    self.joinToken = joinToken
    self.stripeAccountId = stripeAccountId
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.expiresAt = expiresAt
  }

  enum CodingKeys: String, CodingKey {
    case id, title, description, currency, status
    case creatorId = "creator_id"
    case coverPath = "cover_path"
    case goalCents = "goal_cents"
    case raisedCents = "raised_cents"
    case supporterCount = "supporter_count"
    case minTier = "min_tier"
    case isPublic = "is_public"
    case publicSlug = "public_slug"
    case joinToken = "join_token"
    case stripeAccountId = "stripe_account_id"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case expiresAt = "expires_at"
  }
}

public struct CampaignContribution: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public let campaignId: UUID
  public let contributorId: UUID?
  public var displayName: String?
  public var message: String?
  public var amountCents: Int
  public var applicationFeeCents: Int
  public var currency: String
  public var provider: String
  public var providerPaymentId: String?
  public var status: CampaignContributionStatus
  public var isAnonymous: Bool
  public let createdAt: Date

  public init(
    id: UUID = UUID(),
    campaignId: UUID,
    contributorId: UUID? = nil,
    displayName: String? = nil,
    message: String? = nil,
    amountCents: Int,
    applicationFeeCents: Int = 0,
    currency: String = "eur",
    provider: String = "stripe",
    providerPaymentId: String? = nil,
    status: CampaignContributionStatus = .pending,
    isAnonymous: Bool = false,
    createdAt: Date = .now
  ) {
    self.id = id
    self.campaignId = campaignId
    self.contributorId = contributorId
    self.displayName = displayName
    self.message = message
    self.amountCents = amountCents
    self.applicationFeeCents = applicationFeeCents
    self.currency = currency
    self.provider = provider
    self.providerPaymentId = providerPaymentId
    self.status = status
    self.isAnonymous = isAnonymous
    self.createdAt = createdAt
  }

  enum CodingKeys: String, CodingKey {
    case id, message, currency, provider, status
    case campaignId = "campaign_id"
    case contributorId = "contributor_id"
    case displayName = "display_name"
    case amountCents = "amount_cents"
    case applicationFeeCents = "application_fee_cents"
    case providerPaymentId = "provider_payment_id"
    case isAnonymous = "is_anonymous"
    case createdAt = "created_at"
  }
}

/// Anon-readable projection returned by the `public_campaign_by_slug` RPC for the
/// public web landing (no tokens, creator id or Stripe account exposed).
public struct PublicCampaign: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public var title: String
  public var description: String?
  public var coverPath: String?
  public var goalCents: Int
  public var currency: String
  public var raisedCents: Int
  public var supporterCount: Int
  public var status: CampaignStatus
  public let createdAt: Date
  public var expiresAt: Date?

  public var progress: Double {
    guard goalCents > 0 else { return 0 }
    return min(max(Double(raisedCents) / Double(goalCents), 0), 1)
  }

  enum CodingKeys: String, CodingKey {
    case id, title, description, currency, status
    case coverPath = "cover_path"
    case goalCents = "goal_cents"
    case raisedCents = "raised_cents"
    case supporterCount = "supporter_count"
    case createdAt = "created_at"
    case expiresAt = "expires_at"
  }
}

/// One supporter on the public wall (`public_campaign_supporters` RPC).
public struct PublicSupporter: Codable, Hashable, Sendable {
  public var displayName: String?
  public var message: String?
  public var amountCents: Int
  public let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case message
    case displayName = "display_name"
    case amountCents = "amount_cents"
    case createdAt = "created_at"
  }
}
