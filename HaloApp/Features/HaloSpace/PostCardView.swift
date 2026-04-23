import SwiftUI
import HaloShared

/// Step 9: card di un singolo post con caption + mood + reactions bar.
struct PostCardView: View {
  let post: HaloPost
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let caption = post.caption {
        Text(caption).foregroundStyle(.white)
      }
      if let mood = post.mood {
        Text(mood.rawValue).font(.caption).foregroundStyle(HaloTheme.textMuted)
      }
      // TODO step 10: ReactionBarView
    }
    .padding()
    .background(HaloTheme.surface, in: .rect(cornerRadius: HaloTheme.cornerRadius))
  }
}
