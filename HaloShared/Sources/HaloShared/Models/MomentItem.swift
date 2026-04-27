import Foundation

/// Unità del feed/orbital: una persona col suo stato attuale (vibe + ultimo post + tier).
/// "Persona-centrico, non post-centrico": una sola card per persona, opzionalmente con un post agganciato.
public struct MomentItem: Identifiable, Hashable, Sendable {
  public let id: UUID                    // = profile.id
  public let profile: Profile
  public let viewerTier: FriendshipTier? // tier del viewer verso questa persona (nil = non seguita)
  public var vibe: Vibe?
  public var lastPost: HaloPost?
  public var isMutual: Bool

  public init(
    profile: Profile,
    viewerTier: FriendshipTier?,
    vibe: Vibe? = nil,
    lastPost: HaloPost? = nil,
    isMutual: Bool = false
  ) {
    self.id = profile.id
    self.profile = profile
    self.viewerTier = viewerTier
    self.vibe = vibe
    self.lastPost = lastPost
    self.isMutual = isMutual
  }

  /// Tier-rank per ordinare il feed. Inner prima, asteroidi (sconosciuti / asimmetrici) ultimi.
  public var sortRank: Int {
    viewerTier?.rank ?? 0
  }

  /// Quando "vivere" la card: usa l'ultimo evento utile.
  public var lastActivityAt: Date {
    let candidates: [Date] = [vibe?.createdAt, lastPost?.createdAt].compactMap { $0 }
    return candidates.max() ?? .distantPast
  }
}
