import SwiftUI
import HaloShared

/// Step 10: barra delle 6 reazioni emotive.
/// Per viewer Orbit mostra solo il conteggio; per Inner/Close mostra chi ha reagito.
struct ReactionBarView: View {
  let viewerTier: FriendshipTier
  let aggregates: [ReactionsService.Aggregate]
  var onTap: (ReactionKind) -> Void

  var body: some View {
    HStack(spacing: 12) {
      ForEach(ReactionKind.allCases, id: \.self) { kind in
        Button {
          onTap(kind)
        } label: {
          let count = aggregates.first(where: { $0.kind == kind })?.count ?? 0
          Text("\(kind.rawValue) \(count > 0 ? String(count) : "")")
            .font(.caption)
            .foregroundStyle(.white)
        }
      }
    }
  }
}
