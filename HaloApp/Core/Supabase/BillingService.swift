import Foundation
import HaloShared
import Supabase

enum StripeBillingPlan: String, CaseIterable, Identifiable, Sendable {
  case eventGuest = "event_guest"
  case eventPro = "event_pro"
  case eventBeta = "event_beta"
  case eventPostBeta = "event_post_beta"
  case clubStarter = "club_starter"
  case clubPro = "club_pro"
  case clubScale = "club_scale"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .eventGuest: return "Guest"
    case .eventPro: return "Pro"
    case .eventBeta: return "Beta"
    case .eventPostBeta: return "Post beta"
    case .clubStarter: return "Starter"
    case .clubPro: return "Pro"
    case .clubScale: return "Scale"
    }
  }

  var subtitle: String {
    switch self {
    case .eventGuest: return "ticket singolo"
    case .eventPro: return "evento campus"
    case .eventBeta: return "launch partner"
    case .eventPostBeta: return "listino live"
    case .clubStarter: return "club leggero"
    case .clubPro: return "club operativo"
    case .clubScale: return "club scalato"
    }
  }

  var priceText: String {
    switch self {
    case .eventGuest: return "EUR 4.99"
    case .eventPro: return "EUR 29"
    case .eventBeta: return "EUR 79"
    case .eventPostBeta: return "custom"
    case .clubStarter: return "EUR 49/m"
    case .clubPro: return "EUR 99/m"
    case .clubScale: return "EUR 149/m"
    }
  }

  static func available(for kind: RingKind) -> [StripeBillingPlan] {
    switch kind {
    case .event:
      return [.eventGuest, .eventPro, .eventBeta, .eventPostBeta]
    case .club, .course:
      return [.clubStarter, .clubPro, .clubScale]
    case .founder:
      return []
    }
  }
}

@MainActor
final class BillingService {
  static let shared = BillingService()
  private init() {}

  enum BillingError: LocalizedError {
    case missingURL
    case server(String)

    var errorDescription: String? {
      switch self {
      case .missingURL:
        return "Stripe non ha restituito un URL valido."
      case .server(let message):
        return message
      }
    }
  }

  private let client = SupabaseClientProvider.shared

  func checkout(ringId: UUID, plan: StripeBillingPlan) async throws -> URL {
    let response: CheckoutResponse = try await client.functions.invoke(
      "stripe-create-checkout-session",
      options: FunctionInvokeOptions(
        body: CheckoutRequest(ringId: ringId, plan: plan.rawValue)
      ),
      decoder: JSONDecoder()
    )
    guard response.ok else {
      throw BillingError.server(response.error ?? "Checkout Stripe non disponibile.")
    }
    guard let urlString = response.url, let url = URL(string: urlString) else {
      throw BillingError.missingURL
    }
    return url
  }

  func customerPortal(ringId: UUID, stripeCustomerId: String? = nil) async throws -> URL {
    let response: PortalResponse = try await client.functions.invoke(
      "stripe-customer-portal",
      options: FunctionInvokeOptions(
        body: PortalRequest(ringId: ringId, stripeCustomerId: stripeCustomerId)
      ),
      decoder: JSONDecoder()
    )
    guard response.ok else {
      throw BillingError.server(response.error ?? "Portal Stripe non disponibile.")
    }
    guard let urlString = response.url, let url = URL(string: urlString) else {
      throw BillingError.missingURL
    }
    return url
  }
}

private struct CheckoutRequest: Encodable {
  let ringId: UUID
  let plan: String

  enum CodingKeys: String, CodingKey {
    case ringId = "ring_id"
    case plan
  }
}

private struct PortalRequest: Encodable {
  let ringId: UUID
  let stripeCustomerId: String?

  enum CodingKeys: String, CodingKey {
    case ringId = "ring_id"
    case stripeCustomerId = "stripe_customer_id"
  }
}

private struct CheckoutResponse: Decodable {
  let ok: Bool
  let sessionId: String?
  let url: String?
  let plan: String?
  let error: String?
}

private struct PortalResponse: Decodable {
  let ok: Bool
  let id: String?
  let url: String?
  let error: String?
}
