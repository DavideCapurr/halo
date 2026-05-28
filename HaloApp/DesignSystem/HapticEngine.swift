import UIKit
import HaloShared

/// Haptic helper centralizzato. Coerenza tier:
///   inner  → .heavy
///   close  → .medium
///   orbit  → .light
///   nebula → .soft
enum HapticEngine {
  static func tap(for tier: FriendshipTier) {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    switch tier {
    case .inner:    style = .heavy
    case .close:    style = .medium
    case .orbit:    style = .light
    case .nebula:   style = .soft
    case .asteroid: style = .soft
    }
    UIImpactFeedbackGenerator(style: style).impactOccurred()
  }

  static func selection() {
    UISelectionFeedbackGenerator().selectionChanged()
  }

  static func success() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }

  static func warning() {
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
  }
}
