import Foundation
import HaloShared

/// Calcolo posizioni angolari delle bolle sui 4 anelli, riproducendo l'algoritmo
/// del prototipo design:
///  1. Per ogni tier, ordino le persone per `angleFor(id, tier)` (hash stabile).
///  2. Distribuisco uniformemente con step 360/n.
///  3. Aggiungo l'offset di fase per tier (`FriendshipTier.anglePhaseDegrees`).
enum OrbitalLayout {
  struct Placement: Hashable {
    let personId: String
    let tier: FriendshipTier
    /// Angolo finale in radianti.
    let angle: Double
  }

  /// Hash deterministico (id + tier) per ordinare le persone in modo stabile fra render.
  static func angleSeedFor(_ personId: String, tier: FriendshipTier, seed: UInt32 = 7) -> UInt32 {
    var h = seed
    let s = personId + "|" + tier.rawValue
    for u in s.unicodeScalars { h = h &* 31 &+ u.value }
    return h % 360
  }

  static func placements(for people: [(id: String, tier: FriendshipTier)]) -> [Placement] {
    let byTier = Dictionary(grouping: people, by: { $0.tier })
    var out: [Placement] = []
    for tier in FriendshipTier.allCases {
      let group = byTier[tier] ?? []
      guard !group.isEmpty else { continue }
      let sorted = group
        .map { ($0, angleSeedFor($0.id, tier: tier)) }
        .sorted { $0.1 < $1.1 }
      let step = 360.0 / Double(sorted.count)
      let phase = tier.anglePhaseDegrees
      for (idx, item) in sorted.enumerated() {
        let degrees = Double(idx) * step + phase
        let angle = degrees * .pi / 180.0
        out.append(.init(personId: item.0.id, tier: tier, angle: angle))
      }
    }
    return out
  }
}
