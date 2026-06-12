import SwiftUI
import HaloShared

struct BocconiVerifyView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var email: String = ""
  @State private var founderCode: String = ""
  @State private var verification: CampusVerification?
  @State private var isLoading: Bool = true
  @State private var isSubmitting: Bool = false
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 0) {
      topRail
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)

      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          hero
          content
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
      }
      .scrollIndicators(.hidden)

      footer
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
    .background(haloSheetBackground())
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
    .task { await load() }
  }

  private var topRail: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text("BOCCONI / VERIFY")
          .haloEyebrow(SwarmActivationRole.connected.color, size: 8.5, tracking: 2.3)
        Text("campus access")
          .font(HaloType.serif(24, weight: .regular))
          .foregroundStyle(HaloInk.cream)
      }
      Spacer()
      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .font(HaloType.system(12, weight: .semibold))
          .foregroundStyle(HaloInk.creamLow)
          .frame(width: 30, height: 30)
          .background(Circle().fill(SwarmHalo.inkWhisper))
          .overlay(Circle().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
      }
      .buttonStyle(.plain)
    }
  }

  private var hero: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("entra nel cold-start Bocconi.")
        .font(HaloType.serif(28, weight: .regular))
        .foregroundStyle(HaloInk.cream)
      Text("serve email @studbocconi.it e founder code offline.")
        .font(HaloType.ui(13, weight: .regular))
        .foregroundStyle(HaloInk.creamLow)
    }
    .padding(14)
    .swarmSurface(
      .panel,
      in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous),
      activation: .connected
    )
  }

  @ViewBuilder
  private var content: some View {
    if isLoading {
      SwarmLoadingState(label: "verifico stato")
    } else if let verification {
      verifiedState(verification)
    } else {
      form
      if let errorMessage {
        errorText(errorMessage)
      }
    }
  }

  private func verifiedState(_ verification: CampusVerification) -> some View {
    SwarmEmptyState(
      title: "Bocconi verificata.",
      message: "\(verification.email) e dentro Halo Founder.",
      activation: .connected
    )
  }

  private var form: some View {
    VStack(alignment: .leading, spacing: 12) {
      field(
        label: "email campus",
        placeholder: "nome.cognome@studbocconi.it",
        text: $email,
        keyboard: .emailAddress
      )
      field(
        label: "founder code",
        placeholder: "BOCCONI-...",
        text: $founderCode,
        keyboard: .default
      )
    }
  }

  private func field(
    label: String,
    placeholder: String,
    text: Binding<String>,
    keyboard: UIKeyboardType
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .haloEyebrow(HaloInk.creamMute, size: 8.5, tracking: 2.0)
      TextField(placeholder, text: text)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .keyboardType(keyboard)
        .font(HaloType.ui(14, weight: .regular))
        .foregroundStyle(HaloInk.cream)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .haloContentGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput))
    }
  }

  private func errorText(_ message: String) -> some View {
    Text(message)
      .font(HaloType.ui(12, weight: .regular))
      .foregroundStyle(SwarmHalo.attention)
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .swarmSurface(
        .panel,
        in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput, style: .continuous),
        activation: .attention
      )
  }

  private var footer: some View {
    HStack {
      Button("chiudi") { dismiss() }
        .font(HaloType.ui(14, weight: .medium))
        .buttonStyle(.plain)
        .foregroundStyle(HaloInk.creamMute)
      Spacer()
      if verification == nil {
        Button {
          Task { await submit() }
        } label: {
          Text(isSubmitting ? "verifico..." : "verifica")
            .font(HaloType.ui(15, weight: .semibold))
            .foregroundStyle(SwarmHalo.background)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(SwarmActivationRole.connected.color, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting || email.isEmpty || founderCode.isEmpty)
        .opacity((email.isEmpty || founderCode.isEmpty) ? 0.45 : 1)
      }
    }
  }

  @MainActor
  private func load() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      verification = try await CampusVerificationService.shared.currentBocconiVerification()
      if let verification {
        email = verification.email
      }
    } catch {
      errorMessage = SupabaseErrorMessage.describe(
        error,
        fallback: "Non riesco a leggere la verifica Bocconi."
      )
    }
  }

  @MainActor
  private func submit() async {
    guard !isSubmitting else { return }
    isSubmitting = true
    errorMessage = nil
    defer { isSubmitting = false }

    do {
      verification = try await CampusVerificationService.shared.verifyBocconi(
        email: email,
        founderCode: founderCode
      )
    } catch {
      errorMessage = SupabaseErrorMessage.describe(
        error,
        fallback: "Email o founder code non validi."
      )
    }
  }
}

#Preview {
  BocconiVerifyView()
}
