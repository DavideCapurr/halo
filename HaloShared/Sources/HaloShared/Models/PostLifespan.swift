import Foundation

/// Quanto vive un post prima di sparire.
///
/// `easy` è la modalità low-stakes: dura poche ore così non c'è la paura del
/// "resta lì per sempre". È pensata per abbassare la frizione del postare —
/// metti qualcosa, lo vede chi c'è ora, e svanisce.
public enum PostLifespan: String, Codable, Sendable, CaseIterable {
  case easy
  case standard

  /// Durata effettiva tra `created_at` e `expires_at`.
  public var duration: TimeInterval {
    switch self {
    case .easy:     return 3 * 3600   // 3 ore
    case .standard: return 72 * 3600  // 3 giorni
    }
  }

  /// Etichetta breve per la UI (sentence case, voce SWARM).
  public var label: String {
    switch self {
    case .easy:     return "easy"
    case .standard: return "pieno"
    }
  }
}
