import Foundation
import Observation
import HaloShared

@Observable
@MainActor
final class HomeViewModel {
  var follows: [Follow] = []
  var profiles: [UUID: Profile] = [:]
  var vibes: [UUID: Vibe] = [:]

  var placements: [OrbitalLayout.Placement] {
    let users = follows.map { (id: $0.followeeId, tier: $0.tier) }
    return OrbitalLayout.placements(for: users)
  }

  var handlesByUser: [UUID: String] {
    Dictionary(uniqueKeysWithValues: profiles.map { ($0.key, $0.value.handle) })
  }

  func load() async {
    // TODO step 8: combine follows + profiles lookup + vibes + realtime subscribe.
  }
}
