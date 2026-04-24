import Foundation
import Observation
import HaloShared

/// Stub: la HomeView attuale usa direttamente `SeedPeople` per il design demo.
/// Questo VM verrà cablato quando saranno pronti gli step 4-8 (auth, follows,
/// vibes, realtime) e sostituirà il dataset locale.
@Observable
@MainActor
final class HomeViewModel {
  var follows: [Follow] = []
  var profiles: [UUID: Profile] = [:]
  var vibes: [UUID: Vibe] = [:]

  func load() async {
    // TODO step 8: combine follows + profiles lookup + vibes + realtime subscribe.
  }
}
