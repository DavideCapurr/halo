import HaloShared
import Observation
import SwiftUI

/// Penny campaigns hub: the campaigns you run + public campaigns to back.
/// A campaign is a Mike Hayes-style goal funded by many small real donations
/// that travel through the Halo graph (via `minTier`) and a shareable link.
struct CampaignsListView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var vm = CampaignsViewModel()
  @State private var showCreate = false
  @State private var detailCampaign: Campaign?

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: SwarmHalo.s4) {
          rail
          if vm.isLoading && vm.isEmpty {
            SwarmLoadingState(label: "campaigns")
          } else {
            mineSection
            publicSection
            if vm.isEmpty {
              SwarmEmptyState(
                title: "nessuna campagna.",
                message: "lancia la prima: un obiettivo, tante piccole donazioni.",
                activation: .operational
              )
            }
          }
          if let error = vm.errorMessage {
            Text(error)
              .font(HaloType.ui(12, weight: .regular))
              .foregroundStyle(SwarmActivationRole.attention.color)
              .fixedSize(horizontal: false, vertical: true)
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
    .task { await vm.load() }
    .sheet(isPresented: $showCreate) {
      CampaignCreateSheet { created in
        Task { await vm.load() }
        detailCampaign = created
      }
    }
    .sheet(item: $detailCampaign) { campaign in
      CampaignDetailView(campaign: campaign)
    }
  }

  private var rail: some View {
    SwarmOperationalRail(title: "HALO / CAMPAIGNS", context: "penny goal", activation: .operational) {
      HStack(spacing: SwarmHalo.s2) {
        Button(action: { showCreate = true }) {
          Image(systemName: "plus")
            .font(HaloType.system(12, weight: .semibold))
            .foregroundStyle(SwarmActivationRole.operational.color)
            .swarmIconFrame(active: true, activation: .operational)
        }
        .buttonStyle(.plain)

        Button(action: { dismiss() }) {
          Image(systemName: "xmark")
            .font(HaloType.system(12, weight: .semibold))
            .foregroundStyle(SwarmHalo.inkSecondary)
            .swarmIconFrame()
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  private var mineSection: some View {
    if !vm.mine.isEmpty {
      VStack(alignment: .leading, spacing: SwarmHalo.s3) {
        sectionHeader("le tue")
        ForEach(vm.mine) { campaign in
          Button { detailCampaign = campaign } label: {
            CampaignRow(campaign: campaign, isMine: true)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  @ViewBuilder
  private var publicSection: some View {
    if !vm.publicFeed.isEmpty {
      VStack(alignment: .leading, spacing: SwarmHalo.s3) {
        sectionHeader("da sostenere")
        ForEach(vm.publicFeed) { campaign in
          Button { detailCampaign = campaign } label: {
            CampaignRow(campaign: campaign, isMine: false)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private func sectionHeader(_ text: String) -> some View {
    HStack(spacing: SwarmHalo.s2) {
      Text(text)
        .haloEyebrow(SwarmHalo.inkMuted, size: 8.5, tracking: 2.0)
      Rectangle()
        .fill(SwarmHalo.inkLine)
        .frame(height: SwarmStroke.hairline)
    }
  }
}

@Observable
@MainActor
final class CampaignsViewModel {
  var mine: [Campaign] = []
  var publicFeed: [Campaign] = []
  var isLoading = false
  var errorMessage: String?

  var isEmpty: Bool { mine.isEmpty && publicFeed.isEmpty }

  func load() async {
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil

    do {
      async let mineTask = CampaignsService.shared.myCampaigns()
      async let publicTask = CampaignsService.shared.publicCampaigns()
      let (mine, publicAll) = try await (mineTask, publicTask)
      self.mine = mine
      // Don't show my own campaigns twice in the public feed.
      let mineIds = Set(mine.map(\.id))
      self.publicFeed = publicAll.filter { !mineIds.contains($0.id) }
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Non riesco a caricare le campagne.")
    }
  }
}

struct CampaignRow: View {
  let campaign: Campaign
  var isMine: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      HStack(alignment: .top, spacing: SwarmHalo.s3) {
        VStack(alignment: .leading, spacing: 4) {
          Text(campaign.title)
            .font(HaloType.ui(15, weight: .semibold))
            .foregroundStyle(SwarmHalo.ink)
            .lineLimit(2)
          Text(CampaignMoney.progressLine(campaign))
            .font(HaloType.ui(12, weight: .regular))
            .foregroundStyle(SwarmHalo.inkMuted)
            .lineLimit(1)
        }
        Spacer()
        Text(statusLabel)
          .font(HaloType.mono(9, weight: .medium))
          .kerning(1.2)
          .textCase(.uppercase)
          .foregroundStyle(statusColor)
      }
      CampaignProgressBar(progress: campaign.progress, reached: campaign.hasReachedGoal)
    }
    .padding(SwarmHalo.s4)
    .swarmSurface(
      .card,
      in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous),
      activation: campaign.hasReachedGoal ? .operational : .rest
    )
  }

  private var statusLabel: String {
    if !campaign.isCollecting { return "closed" }
    if campaign.hasReachedGoal { return "goal+" }
    return isMine ? "live" : "open"
  }

  private var statusColor: Color {
    if campaign.hasReachedGoal { return SwarmActivationRole.operational.color }
    if !campaign.isCollecting { return SwarmHalo.inkMuted }
    return SwarmActivationRole.connected.color
  }
}

/// Thin progress bar. Shown only on the campaign surface — the social feed stays
/// metric-free per Halo's "no public metrics" rule.
struct CampaignProgressBar: View {
  let progress: Double
  var reached: Bool

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(SwarmHalo.inkWhisper)
        Capsule()
          .fill(reached ? SwarmActivationRole.operational.color : SwarmActivationRole.connected.color)
          .frame(width: max(6, geo.size.width * progress))
      }
    }
    .frame(height: 6)
  }
}

/// Cents → display string and progress copy. Mirrors the cents-based money model
/// used across rings/billing.
enum CampaignMoney {
  static func format(cents: Int, currency: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency.uppercased()
    formatter.maximumFractionDigits = cents % 100 == 0 ? 0 : 2
    let amount = Double(cents) / 100.0
    return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
  }

  static func progressLine(_ campaign: Campaign) -> String {
    let raised = format(cents: campaign.raisedCents, currency: campaign.currency)
    let goal = format(cents: campaign.goalCents, currency: campaign.currency)
    let supporters = campaign.supporterCount
    let people = supporters == 1 ? "1 sostenitore" : "\(supporters) sostenitori"
    return "\(raised) di \(goal) · \(people)"
  }
}
