import SwiftUI
import HaloShared

/// Barra delle 6 reazioni emotive (`ReactionGlyph`).
/// Per viewer Inner/Close espone gli `actors`; per Orbit/Nebula solo il count.
/// `selected` evidenzia le reazioni del viewer corrente (toggle UI immediato).
struct ReactionBarView: View {
  let viewerTier: FriendshipTier
  let aggregates: [ReactionsService.Aggregate]
  /// Set delle ReactionKind che il viewer ha già lasciato.
  var selected: Set<ReactionKind> = []
  /// Mood della persona di cui stiamo guardando il post (per la tinta accesa).
  var accentMood: Mood = .chill
  var onTap: (ReactionKind) -> Void = { _ in }

  private var canSeeActors: Bool {
    viewerTier == .inner || viewerTier == .close
  }

  private func aggregate(for kind: ReactionKind) -> ReactionsService.Aggregate? {
    aggregates.first(where: { $0.kind == kind })
  }

  var body: some View {
    HStack(spacing: 4) {
      ForEach(ReactionKind.allCases, id: \.self) { kind in
        let agg = aggregate(for: kind)
        let on = selected.contains(kind)
        Button { onTap(kind) } label: {
          VStack(spacing: 4) {
            ReactionGlyph(
              kind: kind,
              size: 20,
              color: on
                ? MoodPalette.auraColor(accentMood, l: 0.85)
                : Color.white.opacity(0.45)
            )
            footerLabel(for: kind, agg: agg)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .haloGlass(
            in: RoundedRectangle(cornerRadius: 10),
            tint: on ? MoodPalette.auraColor(accentMood, l: 0.55) : nil,
            interactive: true,
            stroke: on ? HaloTheme.glassStroke : .clear
          )
          .opacity(on ? 1 : 0.72)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
  }

  @ViewBuilder
  private func footerLabel(for kind: ReactionKind, agg: ReactionsService.Aggregate?) -> some View {
    if let agg, agg.count > 0 {
      if canSeeActors, let actors = agg.actors, !actors.isEmpty {
        HStack(spacing: 3) {
          ForEach(actors.prefix(2), id: \.self) { uuid in
            Circle()
              .fill(Color.white.opacity(0.18))
              .frame(width: 10, height: 10)
              .overlay(
                Text(initial(from: uuid))
                  .font(.system(size: 6, weight: .semibold))
                  .foregroundStyle(.white.opacity(0.85))
              )
          }
          if agg.count > 2 {
            Text("+\(agg.count - 2)")
              .font(.system(size: 9, design: .monospaced))
              .foregroundStyle(Color.white.opacity(0.55))
          }
        }
      } else {
        Text("\(agg.count)")
          .font(.system(size: 10, design: .monospaced))
          .foregroundStyle(Color.white.opacity(0.55))
      }
    } else {
      Color.clear.frame(width: 1, height: 10)
    }
  }

  private func initial(from id: UUID) -> String {
    String(id.uuidString.prefix(1)).lowercased()
  }
}
