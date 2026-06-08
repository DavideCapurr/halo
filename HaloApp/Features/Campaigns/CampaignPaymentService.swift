import Foundation
import HaloShared
import StripePaymentSheet
import UIKit

/// Presents Stripe PaymentSheet for a one-tap donation. The PaymentIntent is a
/// direct charge on the creator's connected account, so the SDK is pointed at
/// that account before presenting. Apple Pay gives the single Face ID tap and
/// satisfies SCA without a 3DS screen.
@MainActor
final class CampaignPaymentService {
  static let shared = CampaignPaymentService()
  private init() {}

  /// Apple Pay merchant id. Requires the Apple Pay capability + a matching
  /// merchant id in the Apple Developer account.
  static let applePayMerchantId = "merchant.com.halo.app"

  enum Outcome: Equatable {
    case completed
    case canceled
    case failed(String)
  }

  // Keep the sheet alive until its completion handler fires.
  private var retainedSheet: PaymentSheet?

  func donate(
    campaign: Campaign,
    amountCents: Int,
    displayName: String?,
    message: String?,
    isAnonymous: Bool
  ) async -> Outcome {
    do {
      let params = try await CampaignsService.shared.createPaymentIntent(
        campaignId: campaign.id,
        amountCents: amountCents,
        displayName: displayName,
        message: message,
        isAnonymous: isAnonymous
      )

      STPAPIClient.shared.publishableKey = params.publishableKey
      STPAPIClient.shared.stripeAccount = params.connectedAccountId

      var config = PaymentSheet.Configuration()
      config.merchantDisplayName = campaign.title
      config.applePay = .init(
        merchantId: Self.applePayMerchantId,
        merchantCountryCode: "IT"
      )
      config.allowsDelayedPaymentMethods = false

      let sheet = PaymentSheet(
        paymentIntentClientSecret: params.clientSecret,
        configuration: config
      )
      retainedSheet = sheet

      guard let presenter = Self.topViewController() else {
        retainedSheet = nil
        return .failed("Impossibile aprire il pagamento.")
      }

      return await withCheckedContinuation { continuation in
        sheet.present(from: presenter) { [weak self] result in
          self?.retainedSheet = nil
          switch result {
          case .completed:
            continuation.resume(returning: .completed)
          case .canceled:
            continuation.resume(returning: .canceled)
          case .failed(let error):
            continuation.resume(returning: .failed(error.localizedDescription))
          }
        }
      }
    } catch {
      retainedSheet = nil
      return .failed(SupabaseErrorMessage.describe(error, fallback: "Pagamento non riuscito."))
    }
  }

  private static func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
