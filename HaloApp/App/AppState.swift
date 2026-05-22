import Foundation
import Observation
import HaloShared

@Observable
@MainActor
final class AppState {
  enum Route: Hashable {
    case home
    case haloSpace(userId: UUID)
    case profile(userId: UUID)
  }

  enum Phase {
    case launching     // verifica sessione iniziale
    case signedOut     // SignInView
    case onboarding    // handle / display / avatar
    case initialCircle // primi Inner
    case ready         // Home
  }

  var phase: Phase = .launching
  var currentProfile: Profile?
  var route: Route = .home
  var launchErrorMessage: String?

  var isAuthenticated: Bool { currentProfile != nil }

  // MARK: - Bootstrap

  /// Ripristina lo stato della sessione all'avvio dell'app.
  /// - presente `currentUserId` → carica il profilo:
  ///     - se profilo trovato → `.ready`
  ///     - se profilo manca → `.onboarding` (Apple ha creato l'account ma non il profile)
  /// - assente → `.signedOut`
  func restore() async {
    launchErrorMessage = nil
    if AuthService.shared.currentUserId() != nil {
      do {
        let p = try await ProfilesService.shared.currentProfile()
        currentProfile = p
        phase = .ready
      } catch ProfilesService.ProfilesError.notFound {
        phase = .onboarding
      } catch {
        launchErrorMessage = SupabaseErrorMessage.describe(
          error,
          fallback: "Non riesco a caricare il profilo. Riprova."
        )
        phase = .launching
      }
    } else {
      phase = .signedOut
    }
  }

  // MARK: - Mutations

  func didSignIn(_ profile: Profile) {
    launchErrorMessage = nil
    currentProfile = profile
    // Se manca handle/displayName "veri" siamo ancora in onboarding.
    if profile.handle.hasPrefix("halo_") || profile.displayName == "Halo" {
      phase = .onboarding
    } else {
      phase = initialCircleNeeded ? .initialCircle : .ready
    }
  }

  /// Heuristica: se il profilo è appena stato creato e non ha follow Inner,
  /// passa per `InitialInnerCircleView`. Per ora lasciamo l'utente decidere
  /// se passarci tramite skip esplicito; default = no.
  var initialCircleNeeded: Bool { false }

  func didFinishOnboarding(_ profile: Profile) {
    launchErrorMessage = nil
    currentProfile = profile
    phase = initialCircleNeeded ? .initialCircle : .ready
  }

  func didFinishInitialCircle() {
    phase = .ready
  }

  func didSignOut() {
    launchErrorMessage = nil
    currentProfile = nil
    phase = .signedOut
    route = .home
  }

  // MARK: - Routing

  func handle(link: DeepLink) {
    switch link {
    case .haloSpace(let userId):
      route = .haloSpace(userId: userId)
    }
  }
}
