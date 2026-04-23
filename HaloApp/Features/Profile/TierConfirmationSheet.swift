import SwiftUI
import HaloShared

/// Step 8: sheet di conferma per cambio tier proposto dall'altra parte.
struct TierConfirmationSheet: View {
  let proposer: Profile
  let proposedTier: FriendshipTier
  var onAccept: () -> Void
  var onDecline: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Text("\(proposer.displayName) ti ha spostato/a in \(proposedTier.rawValue.capitalized)")
        .font(.headline)
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
      HStack {
        Button("Rifiuta", action: onDecline)
          .buttonStyle(.bordered)
        Button("Accetta", action: onAccept)
          .buttonStyle(.borderedProminent)
      }
    }
    .padding(24)
    .background(HaloTheme.surface)
  }
}
