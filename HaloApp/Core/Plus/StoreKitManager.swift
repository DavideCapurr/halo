import Foundation
import StoreKit

/// Step 13: Halo Plus €3,99/mese via StoreKit 2, senza RevenueCat.
@MainActor
final class StoreKitManager {
  static let shared = StoreKitManager()
  private init() {}

  static let monthlyProductID = "app.halo.plus.monthly"

  private(set) var isPlus: Bool = false

  enum PlusError: Error { case notImplemented, notEntitled }

  func loadEntitlements() async throws {
    // TODO step 13: Transaction.currentEntitlements → setta isPlus.
  }

  func purchaseMonthly() async throws {
    throw PlusError.notImplemented // TODO step 13
  }
}
