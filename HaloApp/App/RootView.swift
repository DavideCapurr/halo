import SwiftUI
import HaloShared

/// Routing principale: gate auth → onboarding → home.
/// `restore()` viene chiamata all'avvio per ripristinare la sessione esistente.
///
/// Fra l'identità e la Home non c'è nessuno step: `docs/PRODOTTO.md` §7 toglie
/// "scegli i tuoi 5" dal first run. Chi arriva da un QR deve atterrare sul ring
/// dell'evento, non su una schermata che gli chiede di ordinare le proprie
/// amicizie prima di aver visto un solo momento di valore.
struct RootView: View {
  @Environment(AppState.self) private var state

  var body: some View {
    ZStack {
      switch state.phase {
      case .launching:
        launchingView
      case .signedOut:
        SignInView { profile in
          state.didSignIn(profile)
        }
        .transition(.opacity)
      case .onboarding:
        OnboardingView(initialProfile: state.currentProfile ?? bootstrapProfile()) { profile in
          state.didFinishOnboarding(profile)
        }
        .transition(.opacity)
      case .ready:
        HomeView()
          .transition(.opacity)
      }
    }
    .animation(SwarmMotion.mount, value: state.phase)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .task {
      if state.phase == .launching {
        await state.restore()
      }
    }
  }

  // MARK: - subviews

  private var launchingView: some View {
    ZStack {
      DeepSpaceBackground()
      VStack(spacing: 14) {
        Text("Halo")
          .font(HaloType.serifUpright(48, weight: .medium))
          .foregroundStyle(SwarmHalo.ink)
        if let errorMessage = state.launchErrorMessage {
          Text(errorMessage)
            .font(HaloType.ui(13, weight: .regular))
            .foregroundStyle(HaloInk.creamMute)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
          Button {
            Task { await state.restore() }
          } label: {
            Text("riprova")
              .font(HaloType.ui(14, weight: .semibold))
              .foregroundStyle(HaloInk.cream)
              .padding(.horizontal, 18)
              .padding(.vertical, 10)
              .swarmSurface(.control, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput, style: .continuous), activation: .attention)
          }
          .buttonStyle(.plain)
        } else {
          ProgressView().tint(SwarmHalo.ink)
        }
      }
    }
  }

  /// Profilo placeholder se entriamo in onboarding senza un profile pre-caricato.
  private func bootstrapProfile() -> Profile {
    let id = AuthService.shared.currentUserId() ?? UUID()
    return Profile(
      id: id,
      handle: "halo_\(id.uuidString.prefix(6).lowercased())",
      displayName: "Halo"
    )
  }
}
