import SwiftUI
import HaloShared

/// Legacy entry point kept for routes that still reference the old compose
/// surface. It now resolves to the SWARM vibe-first command sheet.
struct ComposePostView: View {
  var body: some View {
    VibeFirstComposeView(
      tierCounts: [.inner: 0, .close: 0, .orbit: 0, .nebula: 0]
    )
  }
}
