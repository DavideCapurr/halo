import SwiftUI
import HaloShared

/// Routing principale: gate auth → onboarding → initial circle → home.
/// `restore()` viene chiamata all'avvio per ripristinare la sessione esistente.
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
      case .initialCircle:
        InitialInnerCircleView(
          onDone: { state.didFinishInitialCircle() },
          onSkip: { state.didFinishInitialCircle() }
        )
        .transition(.opacity)
      case .ready:
        HomeView()
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.30), value: state.phase)
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
          .font(.system(size: 40, weight: .semibold, design: .rounded))
          .foregroundStyle(.white)
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
              .haloGlass(in: RoundedRectangle(cornerRadius: 12), interactive: true)
          }
          .buttonStyle(.plain)
        } else {
          ProgressView().tint(.white.opacity(0.8))
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
