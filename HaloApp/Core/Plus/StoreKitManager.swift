import Foundation
import StoreKit

/// Halo Plus via StoreKit 2, senza RevenueCat.
@MainActor
final class StoreKitManager {
  static let shared = StoreKitManager()
  private init() {}

  static let monthlyProductID = "app.halo.plus.monthly"

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

  func loadEntitlements() async throws {
    var entitled = false
    for await result in Transaction.currentEntitlements {
      let transaction = try verified(result)
      if transaction.productID == Self.monthlyProductID {
        entitled = true
      }
    }
    isPlus = entitled
  }

  func purchaseMonthly() async throws {
    guard let product = try await Product.products(for: [Self.monthlyProductID]).first else {
      throw PlusError.productUnavailable
    }

    let result = try await product.purchase()
    switch result {
    case .success(let verification):
      let transaction = try verified(verification)
      isPlus = transaction.productID == Self.monthlyProductID
      await transaction.finish()
    case .pending:
      throw PlusError.pending
    case .userCancelled:
      throw PlusError.cancelled
    @unknown default:
      throw PlusError.unverified
    }
  }

  private func verified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .verified(let value):
      return value
    case .unverified:
      throw PlusError.unverified
    }
  }
}
