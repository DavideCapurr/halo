import Foundation
import HaloShared

/// Step 3/8: calcola le posizioni delle bolle sui 4 anelli.
/// Spalma gli utenti di ogni tier equidistanti sull'angolo, con offset deterministico per evitare sovrapposizioni perfette.
enum OrbitalLayout {
  struct Placement: Hashable {
    let userId: UUID
    let position: CGPoint   // in coordinate normalizzate [-1, 1]
    let tier: FriendshipTier
  }

  /// - parameter users: ordinati (stabile) per non saltare tra refresh.
  /// - returns: coordinate normalizzate (-1…1). Il renderer moltiplica per il raggio effettivo.
  static func placements(for users: [(id: UUID, tier: FriendshipTier)]) -> [Placement] {
    let byTier = Dictionary(grouping: users, by: { $0.tier })
    var out: [Placement] = []
    for tier in FriendshipTier.allCases {
      let group = byTier[tier] ?? []
      guard !group.isEmpty else { continue }
      let radius = tier.ringRadius
      // Offset di fase per tier così gli anelli non hanno bolle sullo stesso raggio verticale.
      let phaseOffset = Double(tier.rank) * 0.11
      for (idx, u) in group.enumerated() {
        let angle = 2 * .pi * (Double(idx) / Double(group.count)) + phaseOffset
        let x = radius * cos(angle)
        let y = radius * sin(angle)
        out.append(.init(userId: u.id, position: .init(x: x, y: y), tier: tier))
      }
    }
    return out
  }
}
