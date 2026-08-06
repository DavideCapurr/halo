import Foundation
import Observation
import HaloShared

/// Demo/offline mode toggle, attivato passando `HALO_DEMO=1` come variabile
/// d'ambiente al processo (es. da Xcode scheme o `simctl launch`).
///
/// Quando attivo l'app bypassa auth + Supabase e idrata le superfici principali
/// con `SeedPeople`, così da poter ispezionare l'UI con contenuti realistici.
/// Non ha alcun effetto sulle build di produzione (variabile assente → `false`).
enum DemoMode {
  static let isActive: Bool = ProcessInfo.processInfo.environment["HALO_DEMO"] == "1"
}

@Observable
@MainActor
final class AppState {
  enum Route: Hashable {
    case home
    case haloSpace(userId: UUID)
    case profile(userId: UUID)
    case invite(token: String)
    case ring(id: UUID)
    case ringJoin(token: String)
    case report(userId: UUID)
  }

  /// Fasi di avvio. Non c'è nessuno step fra l'identità e la Home:
  /// `docs/PRODOTTO.md` §7 toglie "scegli i tuoi 5" dall'onboarding, perché i
  /// tier si derivano dal comportamento e chiederli al giorno 1 è impossibile
  /// per una matricola o uno studente in exchange — cioè per il nostro utente.
  ///
  /// Vale anche per il loop di acquisizione: chi arriva da un QR atterra sul
  /// ring dell'evento, non su un gate.
  enum Phase: Equatable {
    case launching     // verifica sessione iniziale
    case signedOut     // SignInView
    case onboarding    // handle / display / avatar
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
    if DemoMode.isActive {
      currentProfile = Profile(
        id: UUID(),
        handle: "you",
        displayName: "Tu"
      )
      phase = .ready
      return
    }
    if AuthService.shared.currentUserId() != nil {
      do {
        let p = try await ProfilesService.shared.currentProfile()
        currentProfile = p
        routeAfterAuthenticatedProfile(p)
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
    routeAfterAuthenticatedProfile(profile)
  }

  func didFinishOnboarding(_ profile: Profile) {
    launchErrorMessage = nil
    currentProfile = profile
    routeAfterAuthenticatedProfile(profile)
  }

  func didSignOut() {
    launchErrorMessage = nil
    currentProfile = nil
    phase = .signedOut
    route = .home
  }

  func refreshCurrentProfile() async {
    guard currentProfile != nil else { return }
    do {
      currentProfile = try await ProfilesService.shared.currentProfile()
    } catch {
      // Keep the previous cache if the refresh fails; visible surfaces can retry.
    }
  }

  // MARK: - Routing

  func handle(link: DeepLink) {
    switch link {
    case .haloSpace(let userId):
      route = .haloSpace(userId: userId)
    case .invite(let token):
      route = .invite(token: token)
    case .memory:
      // Memory è congelata (`docs/PRODOTTO.md` §8). Il contratto URL resta
      // valido — il link non deve rompersi — ma non apre più niente: atterra
      // sulla Home invece che su un archivio a pagamento.
      route = .home
    case .ring(let id):
      route = .ring(id: id)
    case .ringJoin(let token):
      route = .ringJoin(token: token)
    case .report(let userId):
      route = .report(userId: userId)
    }
  }

  // MARK: - Phase routing

  private func routeAfterAuthenticatedProfile(_ profile: Profile) {
    currentProfile = profile
    phase = profileNeedsOnboarding(profile) ? .onboarding : .ready
  }

  private func profileNeedsOnboarding(_ profile: Profile) -> Bool {
    profile.handle.hasPrefix("halo_") || profile.displayName == "Halo"
  }
}
