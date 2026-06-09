import Foundation
import StoreKit
import Supabase

/// Halo Plus via StoreKit 2, senza RevenueCat.
@MainActor
final class StoreKitManager {
  static let shared = StoreKitManager()
  private init() {}

  static let monthlyProductID = "app.halo.plus.monthly"

  private let client = SupabaseClientProvider.shared
  private var updatesTask: Task<Void, Never>?

  private(set) var monthlyProduct: Product?
  private(set) var isPlus: Bool = false

  enum PlusError: LocalizedError {
    case productUnavailable
    case pending
    case cancelled
    case unverified

    var errorDescription: String? {
      switch self {
      case .productUnavailable: return "Halo Plus non è disponibile."
      case .pending: return "Acquisto in attesa."
      case .cancelled: return "Acquisto annullato."
      case .unverified: return "Acquisto non verificato."
      }
    }
  }

  var monthlyPriceText: String {
    monthlyProduct?.displayPrice ?? "EUR 2.99"
  }

  func startTransactionListener() {
    guard updatesTask == nil else { return }
    updatesTask = Task { [weak self] in
      for await result in Transaction.updates {
        guard let self else { return }
        do {
          let transaction = try self.verified(result)
          guard transaction.productID == Self.monthlyProductID else {
            await transaction.finish()
            continue
          }
          let entitlement = try await self.syncBackend(jwsRepresentation: result.jwsRepresentation)
          self.isPlus = entitlement.isActive
          await transaction.finish()
        } catch {
          self.isPlus = false
        }
      }
    }
  }

  @discardableResult
  func loadProducts() async throws -> Product {
    if let monthlyProduct { return monthlyProduct }
    guard let product = try await Product.products(for: [Self.monthlyProductID]).first else {
      throw PlusError.productUnavailable
    }
    monthlyProduct = product
    return product
  }

  func loadEntitlements() async throws {
    var entitled = false
    for await result in Transaction.currentEntitlements {
      let transaction = try verified(result)
      if transaction.productID == Self.monthlyProductID {
        let entitlement = try await syncBackend(jwsRepresentation: result.jwsRepresentation)
        entitled = entitlement.isActive
      }
    }
    isPlus = entitled
  }

  func purchaseMonthly() async throws {
    let userId = try AuthService.shared.requireUserId()
    let product = try await loadProducts()

    let result = try await product.purchase(options: [.appAccountToken(userId)])
    switch result {
    case .success(let verification):
      let transaction = try verified(verification)
      guard transaction.productID == Self.monthlyProductID else {
        throw PlusError.productUnavailable
      }
      let entitlement = try await syncBackend(jwsRepresentation: verification.jwsRepresentation)
      isPlus = entitlement.isActive
      await transaction.finish()
    case .pending:
      throw PlusError.pending
    case .userCancelled:
      throw PlusError.cancelled
    @unknown default:
      throw PlusError.unverified
    }
  }

  func restorePurchases() async throws {
    try await AppStore.sync()
    try await loadEntitlements()
  }

  private func verified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .verified(let value):
      return value
    case .unverified:
      throw PlusError.unverified
    }
  }

  private func syncBackend(jwsRepresentation: String) async throws -> StoreKitEntitlement {
    let response: StoreKitSyncResponse = try await client.functions.invoke(
      "apple-storekit-sync",
      options: FunctionInvokeOptions(
        body: StoreKitSyncRequest(signedTransactionInfo: jwsRepresentation)
      ),
      decoder: StoreKitSyncResponse.decoder
    )
    return response.entitlement
  }
}

private struct StoreKitSyncRequest: Encodable {
  let signedTransactionInfo: String
}

private struct StoreKitSyncResponse: Decodable {
  let ok: Bool
  let entitlement: StoreKitEntitlement

  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let value = try container.decode(String.self)
      if let date = ISO8601DateFormatter.storeKitFractional.date(from: value)
        ?? ISO8601DateFormatter.storeKit.date(from: value) {
        return date
      }
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid ISO8601 date: \(value)"
      )
    }
    return decoder
  }
}

private struct StoreKitEntitlement: Decodable {
  let userId: UUID
  let productId: String
  let originalTransactionId: String
  let transactionId: String?
  let status: String
  let currentPeriodStart: Date?
  let currentPeriodEnd: Date?
  let environment: String

  var isActive: Bool {
    guard ["trialing", "active", "grace_period", "billing_retry"].contains(status) else {
      return false
    }
    guard let currentPeriodEnd else { return true }
    return currentPeriodEnd > .now
  }

  enum CodingKeys: String, CodingKey {
    case userId
    case productId
    case originalTransactionId
    case transactionId
    case status
    case currentPeriodStart
    case currentPeriodEnd
    case environment
  }
}

private extension ISO8601DateFormatter {
  static let storeKitFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  static let storeKit: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()
}
