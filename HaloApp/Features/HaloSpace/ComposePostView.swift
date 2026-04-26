import SwiftUI
import HaloShared

/// Step 6: compose post — foto/testo/audio + mood + min_tier.
struct ComposePostView: View {
  @State private var caption: String = ""
  @State private var mood: Mood = .chill
  @State private var minTier: FriendshipTier = .inner

  var body: some View {
    VStack(spacing: 12) {
      Text("Nuovo post").font(.headline).foregroundStyle(.white)
      // TODO step 6: photo picker / audio recorder / mood chips / min_tier selector
      Picker("Visibile da", selection: $minTier) {
        ForEach(FriendshipTier.allCases, id: \.self) { t in
          Text(t.rawValue.capitalized).tag(t)
        }
      }
    }
    .padding()
    .background(HaloTheme.background)
  }
}
