import HaloShared
import SwiftUI

/// Create a penny campaign. `reach` (min tier) reuses the same tier gating as
/// posts: Nebula (default) reaches everyone who follows you, public follows
/// included — the in-Halo half of the Mike Hayes spread.
struct CampaignCreateSheet: View {
  @Environment(\.dismiss) private var dismiss

  var onCreated: (Campaign) -> Void

  @State private var title = ""
  @State private var details = ""
  @State private var goal = ""
  @State private var reach: FriendshipTier = .nebula
  @State private var isPublic = true
  @State private var hasDeadline = false
  @State private var deadline = Date().addingTimeInterval(14 * 24 * 60 * 60)
  @State private var isWorking = false
  @State private var errorMessage: String?

  private let role: SwarmActivationRole = .operational
  private let reachOptions: [FriendshipTier] = [.nebula, .orbit, .close, .inner]

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: SwarmHalo.s4) {
          SwarmOperationalRail(title: "HALO / NEW CAMPAIGN", context: "penny goal", activation: role) {
            Button(action: { dismiss() }) {
              Image(systemName: "xmark")
                .font(HaloType.system(12, weight: .semibold))
                .foregroundStyle(SwarmHalo.inkSecondary)
                .swarmIconFrame()
            }
            .buttonStyle(.plain)
          }

          field("titolo", text: $title)
          field("racconta perché", text: $details)
          field("obiettivo EUR", text: $goal, keyboard: .numberPad)

          reachPanel
          conscienceLine

          Toggle("link pubblico", isOn: $isPublic)
            .font(HaloType.ui(13, weight: .semibold))
            .foregroundStyle(SwarmHalo.ink)
            .tint(role.color)

          Toggle("scadenza", isOn: $hasDeadline)
            .font(HaloType.ui(13, weight: .semibold))
            .foregroundStyle(SwarmHalo.ink)
            .tint(role.color)

          if hasDeadline {
            DatePicker("chiude il", selection: $deadline, displayedComponents: [.date])
              .font(HaloType.ui(13, weight: .semibold))
              .foregroundStyle(SwarmHalo.ink)
          }

          if let errorMessage {
            Text(errorMessage)
              .font(HaloType.ui(12, weight: .regular))
              .foregroundStyle(SwarmActivationRole.attention.color)
              .fixedSize(horizontal: false, vertical: true)
          }

          SwarmCommandButton(
            label: isWorking ? "creo" : "lancia campagna",
            icon: "flag.checkered",
            activation: role,
            isProminent: true
          ) {
            Task { await create() }
          }
          .disabled(isWorking)
          .opacity(isWorking ? 0.6 : 1)
          .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, SwarmHalo.s4)
        .padding(.top, SwarmHalo.s3)
        .padding(.bottom, SwarmHalo.s8)
      }
      .scrollIndicators(.hidden)
    }
    .presentationDetents([.large])
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
  }

  private var reachPanel: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s2) {
      Text("portata")
        .haloEyebrow(SwarmHalo.inkMuted, size: 8.5, tracking: 2.0)
      HStack(spacing: SwarmHalo.s2) {
        ForEach(reachOptions, id: \.self) { tier in
          Button { reach = tier } label: {
            Text(tier.label)
              .font(HaloType.ui(12, weight: .semibold))
              .foregroundStyle(reach == tier ? SwarmHalo.background : SwarmHalo.ink)
              .padding(.horizontal, SwarmHalo.s3)
              .padding(.vertical, 8)
              .background(reach == tier ? role.color : role.fill, in: Capsule())
              .overlay(Capsule().strokeBorder(reach == tier ? role.color : role.stroke, lineWidth: SwarmStroke.standard))
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private var conscienceLine: some View {
    Text(reachHint)
      .font(HaloType.ui(12, weight: .regular))
      .foregroundStyle(SwarmHalo.inkSecondary)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var reachHint: String {
    switch reach {
    case .nebula, .asteroid:
      return "la vedono tutti quelli che ti seguono (anche i follow pubblici). Massima diffusione."
    case .orbit:
      return "la vede chi ti tiene almeno in Orbita."
    case .close:
      return "solo Close e Inner."
    case .inner:
      return "solo il tuo Inner."
    }
  }

  private func field(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
    TextField(placeholder, text: text)
      .keyboardType(keyboard)
      .font(HaloType.ui(14, weight: .regular))
      .foregroundStyle(SwarmHalo.ink)
      .padding(.horizontal, SwarmHalo.s3)
      .padding(.vertical, 12)
      .swarmSurface(.control, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput, style: .continuous), activation: role)
  }

  @MainActor
  private func create() async {
    isWorking = true
    defer { isWorking = false }
    errorMessage = nil

    let goalEuros = Int(goal.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    guard goalEuros > 0 else {
      errorMessage = "Imposta un obiettivo maggiore di zero."
      return
    }

    do {
      let campaign = try await CampaignsService.shared.create(
        title: title,
        description: details,
        goalCents: goalEuros * 100,
        minTier: reach,
        isPublic: isPublic,
        expiresAt: hasDeadline ? deadline : nil
      )
      onCreated(campaign)
      dismiss()
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Campagna non creata.")
    }
  }
}
