import Foundation

public enum RingKind: String, Codable, CaseIterable, Identifiable, Sendable {
  case event
  case club
  case course
  case founder

  public var id: String { rawValue }

  public var label: String {
    switch self {
    case .event: return "event"
    case .club: return "club"
    case .course: return "course"
    case .founder: return "founder"
    }
  }
}

public enum RingMemberRole: String, Codable, CaseIterable, Identifiable, Sendable {
  case owner
  case admin
  case host
  case founder
  case member

  public var id: String { rawValue }
}

public enum RingMemberStatus: String, Codable, CaseIterable, Identifiable, Sendable {
  case active
  case pending
  case removed

  public var id: String { rawValue }
}

public struct HaloRing: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public var kind: RingKind
  public let creatorId: UUID
  public var campusId: UUID?
  public var title: String
  public var subtitle: String?
  public var locationName: String?
  public var startsAt: Date?
  public var endsAt: Date?
  public var expiresAt: Date?
  public var joinToken: String
  public var isPublic: Bool
  public var requiresApproval: Bool
  public var memberLimit: Int?
  public var priceCents: Int?
  public var currency: String
  public let createdAt: Date
  public let updatedAt: Date

  public var isExpired: Bool {
    guard let expiresAt else { return false }
    return expiresAt <= .now
  }

  public var joinURL: URL? {
    DeepLink.ringJoin(token: joinToken).url
  }

  public init(
    id: UUID = UUID(),
    kind: RingKind,
    creatorId: UUID,
    campusId: UUID? = nil,
    title: String,
    subtitle: String? = nil,
    locationName: String? = nil,
    startsAt: Date? = nil,
    endsAt: Date? = nil,
    expiresAt: Date? = nil,
    joinToken: String = "",
    isPublic: Bool = false,
    requiresApproval: Bool = false,
    memberLimit: Int? = nil,
    priceCents: Int? = nil,
    currency: String = "eur",
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = id
    self.kind = kind
    self.creatorId = creatorId
    self.campusId = campusId
    self.title = title
    self.subtitle = subtitle
    self.locationName = locationName
    self.startsAt = startsAt
    self.endsAt = endsAt
    self.expiresAt = expiresAt
    self.joinToken = joinToken
    self.isPublic = isPublic
    self.requiresApproval = requiresApproval
    self.memberLimit = memberLimit
    self.priceCents = priceCents
    self.currency = currency
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  enum CodingKeys: String, CodingKey {
    case id, kind, title, subtitle, currency
    case creatorId = "creator_id"
    case campusId = "campus_id"
    case locationName = "location_name"
    case startsAt = "starts_at"
    case endsAt = "ends_at"
    case expiresAt = "expires_at"
    case joinToken = "join_token"
    case isPublic = "is_public"
    case requiresApproval = "requires_approval"
    case memberLimit = "member_limit"
    case priceCents = "price_cents"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

public struct RingMember: Codable, Identifiable, Hashable, Sendable {
  public let ringId: UUID
  public let userId: UUID
  public var role: RingMemberRole
  public var status: RingMemberStatus
  public let joinedAt: Date
  public let createdAt: Date

  public var id: String { "\(ringId.uuidString):\(userId.uuidString)" }

  public init(
    ringId: UUID,
    userId: UUID,
    role: RingMemberRole = .member,
    status: RingMemberStatus = .active,
    joinedAt: Date = .now,
    createdAt: Date = .now
  ) {
    self.ringId = ringId
    self.userId = userId
    self.role = role
    self.status = status
    self.joinedAt = joinedAt
    self.createdAt = createdAt
  }

  enum CodingKeys: String, CodingKey {
    case role, status
    case ringId = "ring_id"
    case userId = "user_id"
    case joinedAt = "joined_at"
    case createdAt = "created_at"
  }
}

public struct EventCheckIn: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public let ringId: UUID
  public let userId: UUID
  public let source: String
  public let checkedInAt: Date

  public init(
    id: UUID = UUID(),
    ringId: UUID,
    userId: UUID,
    source: String = "qr",
    checkedInAt: Date = .now
  ) {
    self.id = id
    self.ringId = ringId
    self.userId = userId
    self.source = source
    self.checkedInAt = checkedInAt
  }

  enum CodingKeys: String, CodingKey {
    case id, source
    case ringId = "ring_id"
    case userId = "user_id"
    case checkedInAt = "checked_in_at"
  }
}

public struct RingSubscription: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public let ringId: UUID
  public let userId: UUID
  public var provider: String
  public var providerSubscriptionId: String?
  public var status: String
  public var currentPeriodStart: Date?
  public var currentPeriodEnd: Date?
  public var plan: String?
  public let createdAt: Date
  public let updatedAt: Date

  public init(
    id: UUID = UUID(),
    ringId: UUID,
    userId: UUID,
    provider: String = "manual",
    providerSubscriptionId: String? = nil,
    status: String = "active",
    currentPeriodStart: Date? = nil,
    currentPeriodEnd: Date? = nil,
    plan: String? = nil,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = id
    self.ringId = ringId
    self.userId = userId
    self.provider = provider
    self.providerSubscriptionId = providerSubscriptionId
    self.status = status
    self.currentPeriodStart = currentPeriodStart
    self.currentPeriodEnd = currentPeriodEnd
    self.plan = plan
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  enum CodingKeys: String, CodingKey {
    case id, provider, status, plan
    case ringId = "ring_id"
    case userId = "user_id"
    case providerSubscriptionId = "provider_subscription_id"
    case currentPeriodStart = "current_period_start"
    case currentPeriodEnd = "current_period_end"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

public struct ClubBilling: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public let ringId: UUID
  public let subscriptionId: UUID?
  public let payerId: UUID
  public var provider: String
  public var amountCents: Int
  public var currency: String
  public var status: String
  public var periodStart: Date?
  public var periodEnd: Date?
  public var plan: String?
  public var providerInvoiceId: String?
  public var providerCheckoutSessionId: String?
  public let createdAt: Date

  public init(
    id: UUID = UUID(),
    ringId: UUID,
    subscriptionId: UUID? = nil,
    payerId: UUID,
    provider: String = "stripe",
    amountCents: Int,
    currency: String = "eur",
    status: String = "open",
    periodStart: Date? = nil,
    periodEnd: Date? = nil,
    plan: String? = nil,
    providerInvoiceId: String? = nil,
    providerCheckoutSessionId: String? = nil,
    createdAt: Date = .now
  ) {
    self.id = id
    self.ringId = ringId
    self.subscriptionId = subscriptionId
    self.payerId = payerId
    self.provider = provider
    self.amountCents = amountCents
    self.currency = currency
    self.status = status
    self.periodStart = periodStart
    self.periodEnd = periodEnd
    self.plan = plan
    self.providerInvoiceId = providerInvoiceId
    self.providerCheckoutSessionId = providerCheckoutSessionId
    self.createdAt = createdAt
  }

  enum CodingKeys: String, CodingKey {
    case id, provider, currency, status, plan
    case ringId = "ring_id"
    case subscriptionId = "subscription_id"
    case payerId = "payer_id"
    case amountCents = "amount_cents"
    case periodStart = "period_start"
    case periodEnd = "period_end"
    case providerInvoiceId = "provider_invoice_id"
    case providerCheckoutSessionId = "provider_checkout_session_id"
    case createdAt = "created_at"
  }
}
