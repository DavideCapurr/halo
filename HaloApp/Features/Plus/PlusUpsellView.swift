import SwiftUI

/// Halo Plus surface. StoreKit wiring can arrive later; the product surface is
/// no longer a placeholder.
struct PlusUpsellView: View {
  @Environment(AppState.self) private var state
  @Environment(\.dismiss) private var dismiss
  @State private var isWorking = false
  @State private var isRestoring = false
  @State private var priceText = StoreKitManager.shared.monthlyPriceText
  @State private var errorMessage: String?

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: SwarmHalo.s4) {
          rail
          hero
          feature("Memory", "riapri i frammenti del semestre.", .connected)
          feature("Inner archive", "tieni separato ciò che resta vicino.", .operational)
          feature("Event recap", "persone incontrate, Moment salvati, zero pubblico.", .attention)
          feature("Vibe+ presets", "biblioteca, loggia, aula 4 e preset salvati.", .connected)
          feature("Halo skin", "profilo e widget con badge sottile opzionale.", .rest)
          if let errorMessage {
            Text(errorMessage)
              .font(HaloType.ui(12, weight: .regular))
              .foregroundStyle(SwarmActivationRole.attention.color)
              .frame(maxWidth: .infinity, alignment: .trailing)
          }
          HStack(spacing: SwarmHalo.s3) {
            SwarmCommandButton(
              label: isWorking ? "attivazione" : "attiva Halo Plus",
              icon: "sparkles",
              activation: .attention,
              isProminent: true
            ) {
              Task { await purchase() }
            }
            .disabled(isWorking || isRestoring)
            .opacity(isWorking ? 0.62 : 1)

            SwarmCommandButton(
              label: isRestoring ? "restore" : "restore",
              icon: "arrow.clockwise",
              activation: .rest
            ) {
              Task { await restore() }
            }
            .disabled(isWorking || isRestoring)
            .opacity(isRestoring ? 0.62 : 1)
          }
          .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, SwarmHalo.s4)
        .padding(.top, SwarmHalo.s3)
        .padding(.bottom, SwarmHalo.s8)
      }
    }
    .presentationDetents([.large])
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
    .task {
      await loadProductAndEntitlements()
    }
  }

  private var rail: some View {
    SwarmOperationalRail(title: "HALO / PLUS", context: "memory surface", activation: .attention) {
      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .font(HaloType.system(12, weight: .semibold))
          .foregroundStyle(SwarmHalo.inkSecondary)
          .swarmIconFrame()
      }
      .buttonStyle(.plain)
    }
  }

  private var hero: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      Text("i tuoi frammenti. Non il feed.")
        .font(HaloType.serif(40, weight: .regular))
        .foregroundStyle(SwarmHalo.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text("Halo Plus tiene memoria senza trasformarla in metrica.")
        .font(HaloType.ui(14, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
      HStack(spacing: SwarmHalo.s3) {
        SwarmMetricTile(label: "mese", value: priceText, activation: .attention, active: true)
        Rectangle().fill(SwarmHalo.inkLine).frame(width: SwarmStroke.hairline, height: 28)
        SwarmMetricTile(label: "pubblico", value: "00", activation: .rest, active: false)
      }
      .padding(.vertical, SwarmHalo.s3)
    }
    .padding(SwarmHalo.s4)
    .swarmSurface(.sheet, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: .attention)
  }

  private func feature(_ title: String, _ body: String, _ role: SwarmActivationRole) -> some View {
    HStack(alignment: .top, spacing: SwarmHalo.s3) {
      Circle()
        .fill(role.color)
        .frame(width: 8, height: 8)
        .shadow(color: role.glow, radius: 8)
        .padding(.top, 5)
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(HaloType.ui(15, weight: .semibold))
          .foregroundStyle(SwarmHalo.ink)
        Text(body)
          .font(HaloType.ui(13, weight: .regular))
          .foregroundStyle(SwarmHalo.inkSecondary)
      }
      Spacer()
    }
    .padding(SwarmHalo.s4)
    .swarmPanel()
  }

  @MainActor
  private func loadProductAndEntitlements() async {
    do {
      _ = try await StoreKitManager.shared.loadProducts()
      priceText = StoreKitManager.shared.monthlyPriceText
      try await StoreKitManager.shared.loadEntitlements()
      await state.refreshCurrentProfile()
    } catch {
      priceText = StoreKitManager.shared.monthlyPriceText
    }
  }

  @MainActor
  private func purchase() async {
    isWorking = true
    defer { isWorking = false }
    do {
      try await StoreKitManager.shared.purchaseMonthly()
      await state.refreshCurrentProfile()
      errorMessage = nil
      dismiss()
    } catch {
      errorMessage = (error as? LocalizedError)?.errorDescription ?? "Non riesco ad attivare Halo Plus."
    }
  }

  @MainActor
  private func restore() async {
    isRestoring = true
    defer { isRestoring = false }
    do {
      try await StoreKitManager.shared.restorePurchases()
      await state.refreshCurrentProfile()
      if state.currentProfile?.hasPlus == true {
        errorMessage = nil
        dismiss()
      } else {
        errorMessage = "Nessun Halo Plus attivo da ripristinare."
      }
    } catch {
      errorMessage = (error as? LocalizedError)?.errorDescription ?? "Restore non riuscito."
    }
  }
}
