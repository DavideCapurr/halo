import HaloShared
import SwiftUI

/// Pick an amount and donate with one tap (Apple Pay). The chosen amount is
/// remembered so the next donation is effectively configure-once, tap-once.
struct CampaignDonateSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(AppState.self) private var state

  let campaign: Campaign
  var onPaid: () -> Void

  @State private var amount: Int
  @State private var message = ""
  @State private var isAnonymous = false
  @State private var isWorking = false
  @State private var errorMessage: String?

  private let presets = [1, 2, 5, 10, 20]
  private let role: SwarmActivationRole = .operational
  private static let defaultAmountKey = "halo.campaign.defaultAmount"

  init(campaign: Campaign, onPaid: @escaping () -> Void) {
    self.campaign = campaign
    self.onPaid = onPaid
    let saved = UserDefaults.standard.integer(forKey: Self.defaultAmountKey)
    _amount = State(initialValue: saved > 0 ? saved : 1)
  }

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: SwarmHalo.s4) {
          SwarmOperationalRail(title: "HALO / DONA", context: campaign.title, activation: role) {
            Button(action: { dismiss() }) {
              Image(systemName: "xmark")
                .font(HaloType.system(12, weight: .semibold))
                .foregroundStyle(SwarmHalo.inkSecondary)
                .swarmIconFrame()
            }
            .buttonStyle(.plain)
          }

          amountPanel
          field("un messaggio (opzionale)", text: $message)

          Toggle("dona in anonimo", isOn: $isAnonymous)
            .font(HaloType.ui(13, weight: .semibold))
            .foregroundStyle(SwarmHalo.ink)
            .tint(role.color)

          if let errorMessage {
            Text(errorMessage)
              .font(HaloType.ui(12, weight: .regular))
              .foregroundStyle(SwarmActivationRole.attention.color)
              .fixedSize(horizontal: false, vertical: true)
          }

          SwarmCommandButton(
            label: isWorking ? "attendi" : "dona \(CampaignMoney.format(cents: amount * 100, currency: campaign.currency))",
            icon: "applelogo",
            activation: role,
            isProminent: true
          ) {
            Task { await donate() }
          }
          .disabled(isWorking)
          .opacity(isWorking ? 0.6 : 1)
          .frame(maxWidth: .infinity, alignment: .trailing)

          Text("il pagamento va diretto a chi ha creato la campagna. Halo trattiene solo una piccola commissione.")
            .font(HaloType.ui(11, weight: .regular))
            .foregroundStyle(SwarmHalo.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, SwarmHalo.s4)
        .padding(.top, SwarmHalo.s3)
        .padding(.bottom, SwarmHalo.s8)
      }
      .scrollIndicators(.hidden)
    }
    .presentationDetents([.medium, .large])
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
  }

  private var amountPanel: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      Text("importo")
        .haloEyebrow(SwarmHalo.inkMuted, size: 8.5, tracking: 2.0)
      HStack(spacing: SwarmHalo.s2) {
        ForEach(presets, id: \.self) { value in
          Button { amount = value } label: {
            Text(CampaignMoney.format(cents: value * 100, currency: campaign.currency))
              .font(HaloType.ui(13, weight: .semibold))
              .foregroundStyle(amount == value ? SwarmHalo.background : SwarmHalo.ink)
              .padding(.horizontal, SwarmHalo.s3)
              .padding(.vertical, 9)
              .background(amount == value ? role.color : role.fill, in: Capsule())
              .overlay(Capsule().strokeBorder(amount == value ? role.color : role.stroke, lineWidth: SwarmStroke.standard))
          }
          .buttonStyle(.plain)
        }
      }
      Stepper(value: $amount, in: 1...10000) {
        Text("personalizza: \(CampaignMoney.format(cents: amount * 100, currency: campaign.currency))")
          .font(HaloType.ui(13, weight: .regular))
          .foregroundStyle(SwarmHalo.inkSecondary)
      }
      .tint(role.color)
    }
    .padding(SwarmHalo.s4)
    .swarmPanel()
  }

  private func field(_ placeholder: String, text: Binding<String>) -> some View {
    TextField(placeholder, text: text)
      .font(HaloType.ui(14, weight: .regular))
      .foregroundStyle(SwarmHalo.ink)
      .padding(.horizontal, SwarmHalo.s3)
      .padding(.vertical, 12)
      .swarmSurface(.control, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput, style: .continuous), activation: role)
  }

  @MainActor
  private func donate() async {
    isWorking = true
    errorMessage = nil
    UserDefaults.standard.set(amount, forKey: Self.defaultAmountKey)

    let donorName = isAnonymous ? nil : state.currentProfile?.displayName
    let outcome = await CampaignPaymentService.shared.donate(
      campaign: campaign,
      amountCents: amount * 100,
      displayName: donorName,
      message: message,
      isAnonymous: isAnonymous
    )

    switch outcome {
    case .completed:
      onPaid()
      dismiss()
    case .canceled:
      isWorking = false
    case .failed(let reason):
      isWorking = false
      errorMessage = reason
    }
  }
}
