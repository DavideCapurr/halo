import HaloShared
import Observation
import SwiftUI

/// Single campaign surface: progress toward the goal, supporters, share, and the
/// donate entry point. Real donations (Stripe Connect + Apple Pay one-tap) land
/// in a later phase — here the donate button explains what's coming.
struct CampaignDetailView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var vm = CampaignDetailViewModel()
  @State private var showDonate = false
  @State private var isOnboarding = false
  @Environment(\.openURL) private var openURL

  private let source: Source

  private enum Source {
    case campaign(Campaign)
    case id(UUID)
    case slug(String)
  }

  init(campaign: Campaign) { self.source = .campaign(campaign) }
  init(campaignId: UUID) { self.source = .id(campaignId) }
  init(contributeSlug: String) { self.source = .slug(contributeSlug) }

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: SwarmHalo.s4) {
          rail
          if vm.isLoading && !vm.hasContent {
            SwarmLoadingState(label: "campaign")
          } else if vm.hasContent {
            header
            progressPanel
            if vm.needsOnboarding { onboardingBanner }
            actions
            feedback
            supportersPanel
          } else {
            SwarmEmptyState(
              title: "campagna non trovata.",
              message: "il link potrebbe essere scaduto o privato.",
              activation: .attention
            )
          }
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
    .task { await bootstrap() }
    .sheet(isPresented: $showDonate) {
      if let donatable = vm.donatableCampaign {
        CampaignDonateSheet(campaign: donatable) {
          Task { await vm.refreshAfterDonation() }
        }
      }
    }
  }

  private var onboardingBanner: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      Text("collega i pagamenti per ricevere le donazioni. I fondi arrivano diretti sul tuo conto Stripe — Halo non li tocca.")
        .font(HaloType.ui(13, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
      SwarmCommandButton(
        label: isOnboarding ? "apro" : "collega pagamenti",
        icon: "creditcard",
        activation: .attention,
        isProminent: true
      ) {
        Task {
          isOnboarding = true
          defer { isOnboarding = false }
          if let url = await vm.startOnboarding() { openURL(url) }
        }
      }
      .disabled(isOnboarding)
      .opacity(isOnboarding ? 0.6 : 1)
    }
    .padding(SwarmHalo.s4)
    .swarmSurface(.card, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: .attention)
  }

  private var rail: some View {
    SwarmOperationalRail(title: "HALO / CAMPAIGN", context: vm.isCreator ? "la tua" : "sostieni", activation: .operational) {
      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .font(HaloType.system(12, weight: .semibold))
          .foregroundStyle(SwarmHalo.inkSecondary)
          .swarmIconFrame()
      }
      .buttonStyle(.plain)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      Text(vm.title.lowercased())
        .font(HaloType.serif(36, weight: .regular))
        .foregroundStyle(SwarmHalo.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let description = vm.description, !description.isEmpty {
        Text(description)
          .font(HaloType.ui(14, weight: .regular))
          .foregroundStyle(SwarmHalo.inkSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var progressPanel: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s4) {
      CampaignProgressBar(progress: vm.progress, reached: vm.hasReachedGoal)
      HStack(spacing: 0) {
        SwarmMetricTile(
          label: "raccolti",
          value: CampaignMoney.format(cents: vm.raisedCents, currency: vm.currency),
          activation: .operational,
          active: vm.raisedCents > 0
        )
        .frame(maxWidth: .infinity)
        divider
        SwarmMetricTile(
          label: "obiettivo",
          value: CampaignMoney.format(cents: vm.goalCents, currency: vm.currency),
          activation: .rest
        )
        .frame(maxWidth: .infinity)
        divider
        SwarmMetricTile(
          label: "sostenitori",
          value: String(format: "%02d", vm.supporterCount),
          activation: .connected,
          active: vm.supporterCount > 0
        )
        .frame(maxWidth: .infinity)
      }
      Text(vm.statusLine)
        .font(HaloType.ui(12, weight: .regular))
        .foregroundStyle(vm.hasReachedGoal ? SwarmActivationRole.operational.color : SwarmHalo.inkMuted)
    }
    .padding(SwarmHalo.s4)
    .swarmSurface(
      .card,
      in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous),
      activation: vm.hasReachedGoal ? .operational : .rest
    )
  }

  private var actions: some View {
    HStack(spacing: SwarmHalo.s3) {
      if vm.isCollecting && !vm.needsOnboarding {
        SwarmCommandButton(label: "dona", icon: "heart.fill", activation: .operational, isProminent: true) {
          showDonate = true
        }
      }

      if let url = vm.shareURL {
        ShareLink(item: url) {
          Label("condividi", systemImage: "square.and.arrow.up")
            .font(HaloType.ui(13, weight: .semibold))
            .foregroundStyle(SwarmHalo.ink)
            .padding(.horizontal, SwarmHalo.s4)
            .padding(.vertical, 10)
            .background(SwarmActivationRole.rest.fill, in: Capsule())
            .overlay(Capsule().strokeBorder(SwarmActivationRole.rest.stroke, lineWidth: SwarmStroke.standard))
        }
      }

      if vm.isCreator && vm.isCollecting {
        Button { Task { await vm.close() } } label: {
          Image(systemName: "flag.slash")
            .font(HaloType.system(14, weight: .semibold))
            .foregroundStyle(SwarmHalo.ink)
            .swarmIconFrame()
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  private var feedback: some View {
    if let error = vm.errorMessage {
      Text(error)
        .font(HaloType.ui(12, weight: .regular))
        .foregroundStyle(SwarmActivationRole.attention.color)
        .fixedSize(horizontal: false, vertical: true)
    } else if let status = vm.statusMessage {
      Text(status)
        .font(HaloType.ui(12, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  private var supportersPanel: some View {
    let rows = vm.supporterRows
    if !rows.isEmpty {
      VStack(alignment: .leading, spacing: SwarmHalo.s3) {
        HStack(spacing: SwarmHalo.s2) {
          Text("sostenitori")
            .haloEyebrow(SwarmHalo.inkMuted, size: 8.5, tracking: 2.0)
          Rectangle().fill(SwarmHalo.inkLine).frame(height: SwarmStroke.hairline)
        }
        ForEach(rows) { row in
          HStack(spacing: SwarmHalo.s3) {
            VStack(alignment: .leading, spacing: 3) {
              Text(row.name)
                .font(HaloType.ui(13, weight: .semibold))
                .foregroundStyle(SwarmHalo.ink)
                .lineLimit(1)
              if let message = row.message, !message.isEmpty {
                Text(message)
                  .font(HaloType.ui(12, weight: .regular))
                  .foregroundStyle(SwarmHalo.inkMuted)
                  .lineLimit(2)
              }
            }
            Spacer()
            Text(CampaignMoney.format(cents: row.amountCents, currency: vm.currency))
              .font(HaloType.mono(12, weight: .semibold))
              .foregroundStyle(SwarmActivationRole.operational.color)
          }
          .padding(SwarmHalo.s3)
          .swarmSurface(.card, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous))
        }
      }
    }
  }

  private var divider: some View {
    Rectangle()
      .fill(SwarmHalo.inkLine)
      .frame(width: SwarmStroke.hairline, height: 28)
  }

  @MainActor
  private func bootstrap() async {
    switch source {
    case .campaign(let campaign):
      await vm.start(campaign: campaign)
    case .id(let id):
      await vm.start(id: id)
    case .slug(let slug):
      await vm.start(slug: slug)
    }
  }
}

@Observable
@MainActor
final class CampaignDetailViewModel {
  var campaign: Campaign?
  var publicCampaign: PublicCampaign?
  var contributions: [CampaignContribution] = []
  var supporters: [PublicSupporter] = []
  var connect: CampaignsService.ConnectStatus?
  var isLoading = false
  var statusMessage: String?
  var errorMessage: String?

  private var entrySlug: String?
  private var didBootstrap = false
  private let currentUserId = AuthService.shared.currentUserId()

  // MARK: Display accessors (prefer the full campaign, fall back to public view)

  var hasContent: Bool { campaign != nil || publicCampaign != nil }
  var title: String { campaign?.title ?? publicCampaign?.title ?? "" }
  var description: String? { campaign?.description ?? publicCampaign?.description }
  var goalCents: Int { campaign?.goalCents ?? publicCampaign?.goalCents ?? 0 }
  var raisedCents: Int { campaign?.raisedCents ?? publicCampaign?.raisedCents ?? 0 }
  var supporterCount: Int { campaign?.supporterCount ?? publicCampaign?.supporterCount ?? 0 }
  var currency: String { campaign?.currency ?? publicCampaign?.currency ?? "eur" }

  var progress: Double {
    guard goalCents > 0 else { return 0 }
    return min(max(Double(raisedCents) / Double(goalCents), 0), 1)
  }

  var hasReachedGoal: Bool { goalCents > 0 && raisedCents >= goalCents }

  var isCollecting: Bool {
    if let campaign { return campaign.isCollecting }
    if let publicCampaign {
      let expired = publicCampaign.expiresAt.map { $0 <= .now } ?? false
      return publicCampaign.status == .active && !expired
    }
    return false
  }

  var isCreator: Bool {
    guard let campaign, let currentUserId else { return false }
    return campaign.creatorId == currentUserId
  }

  var shareURL: URL? {
    if let campaign { return campaign.contributeDeepLink }
    if let entrySlug { return DeepLink.campaignContribute(slug: entrySlug).url }
    return nil
  }

  /// Creator hasn't finished Stripe onboarding, so the campaign can't receive yet.
  var needsOnboarding: Bool {
    isCreator && (connect?.chargesEnabled != true)
  }

  /// Campaign suitable to hand to the donate flow (synthesized from the public
  /// projection when the full row isn't visible to this viewer).
  var donatableCampaign: Campaign? {
    if let campaign { return campaign }
    guard let p = publicCampaign else { return nil }
    return Campaign(
      id: p.id,
      creatorId: UUID(),
      title: p.title,
      description: p.description,
      goalCents: p.goalCents,
      currency: p.currency,
      raisedCents: p.raisedCents,
      supporterCount: p.supporterCount,
      status: p.status,
      publicSlug: entrySlug ?? "",
      expiresAt: p.expiresAt
    )
  }

  var statusLine: String {
    if hasReachedGoal { return "traguardo raggiunto — e si può ancora dare." }
    if !isCollecting { return "campagna chiusa." }
    let remaining = max(goalCents - raisedCents, 0)
    return "mancano \(CampaignMoney.format(cents: remaining, currency: currency))."
  }

  struct SupporterRow: Identifiable {
    let id: String
    let name: String
    let message: String?
    let amountCents: Int
  }

  /// Prefer the creator/contributor private list; fall back to the public wall.
  var supporterRows: [SupporterRow] {
    if !contributions.isEmpty {
      return contributions
        .filter { $0.status == .paid }
        .map { c in
          SupporterRow(
            id: c.id.uuidString,
            name: c.isAnonymous ? "anonimo" : (c.displayName ?? "sostenitore"),
            message: c.message,
            amountCents: c.amountCents
          )
        }
    }
    return supporters.enumerated().map { idx, s in
      SupporterRow(
        id: "\(idx)",
        name: s.displayName ?? "sostenitore",
        message: s.message,
        amountCents: s.amountCents
      )
    }
  }

  // MARK: Loading

  func start(campaign: Campaign) async {
    guard !didBootstrap else { return }
    didBootstrap = true
    self.campaign = campaign
    self.entrySlug = campaign.publicSlug
    await loadContributions(for: campaign.id)
    await loadConnect()
  }

  func start(id: UUID) async {
    guard !didBootstrap else { return }
    didBootstrap = true
    await reload(id: id)
  }

  func start(slug: String) async {
    guard !didBootstrap else { return }
    didBootstrap = true
    entrySlug = slug
    isLoading = true
    defer { isLoading = false }
    do {
      let pub = try await CampaignsService.shared.publicCampaign(slug: slug)
      publicCampaign = pub
      // If the viewer can see the full row (creator / follower at tier), upgrade.
      if let pub {
        if let full = try? await CampaignsService.shared.campaign(id: pub.id) {
          campaign = full
          entrySlug = full.publicSlug
          await loadContributions(for: full.id)
          await loadConnect()
        } else {
          supporters = (try? await CampaignsService.shared.publicSupporters(slug: slug)) ?? []
        }
      }
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Non riesco a caricare la campagna.")
    }
  }

  private func reload(id: UUID) async {
    isLoading = true
    defer { isLoading = false }
    do {
      let full = try await CampaignsService.shared.campaign(id: id)
      campaign = full
      entrySlug = full.publicSlug
      await loadContributions(for: id)
      await loadConnect()
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Non riesco a caricare la campagna.")
    }
  }

  private func loadContributions(for id: UUID) async {
    contributions = (try? await CampaignsService.shared.contributions(for: id)) ?? []
  }

  private func loadConnect() async {
    guard isCreator else { return }
    connect = try? await CampaignsService.shared.connectStatus()
  }

  /// Begin Stripe Connect onboarding; returns the hosted URL to open.
  func startOnboarding() async -> URL? {
    errorMessage = nil
    do {
      return try await CampaignsService.shared.startConnectOnboarding()
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Onboarding non riuscito.")
      return nil
    }
  }

  /// Refresh after a donation completes (totals settle once the webhook lands).
  func refreshAfterDonation() async {
    statusMessage = "grazie! il totale si aggiorna appena Stripe conferma."
    if let id = campaign?.id {
      await reload(id: id)
    }
  }

  func close() async {
    guard let campaign else { return }
    errorMessage = nil
    do {
      let updated = try await CampaignsService.shared.setStatus(.closed, campaignId: campaign.id)
      self.campaign = updated
      statusMessage = "campagna chiusa."
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Non riesco a chiudere la campagna.")
    }
  }
}
