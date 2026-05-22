import SwiftUI
import HaloShared

/// Sheet di conferma cambio tier proposto via drag.
/// Mostra: titolo "Porta più vicino?" / "Sposta più distante?" + diagramma badge tier
/// + spiegazione cosa cambia in visibilità + due CTA.
struct TierConfirmationSheet: View {
  struct Proposal: Equatable {
    let person: DemoPerson
    let from: FriendshipTier
    let to: FriendshipTier
    var closer: Bool { to.rank > from.rank } // verso inner (più alto)
  }

  let proposal: Proposal
  var onAccept: () -> Void = {}
  var onDecline: () -> Void = {}

  var body: some View {
    VStack(spacing: 0) {
      header
      diagram
      explanation
      actions
    }
    .padding(.bottom, 30)
    .background(haloSheetBackground())
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
  }

  private var header: some View {
    VStack(spacing: 8) {
      Text("SPOSTA NEL TUO HALO")
        .font(.system(size: 13, weight: .medium))
        .kerning(1.5)
        .foregroundStyle(HaloTheme.textCaption)

      VStack(spacing: 2) {
        HStack(spacing: 5) {
          Text(proposal.closer ? "Porta" : "Sposta")
            .foregroundStyle(.white)
          Text(proposal.person.name)
            .foregroundStyle(MoodPalette.auraColor(proposal.person.mood, l: 0.85))
        }
        Text(proposal.closer ? "più vicino?" : "più distante?")
          .foregroundStyle(.white)
      }
      .font(.system(size: 24, weight: .semibold))
      .kerning(-0.5)
      .multilineTextAlignment(.center)
    }
    .padding(.horizontal, 22).padding(.top, 22).padding(.bottom, 8)
  }

  private var diagram: some View {
    HStack(spacing: 22) {
      tierBadge(proposal.from, dimmed: true, highlight: nil)
      Image(systemName: "arrow.right")
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(Color.white.opacity(0.55))
      tierBadge(proposal.to, dimmed: false, highlight: MoodPalette.auraColor(proposal.person.mood, l: 0.75))
    }
    .padding(.vertical, 22)
  }

  private func tierBadge(_ tier: FriendshipTier, dimmed: Bool, highlight: Color?) -> some View {
    VStack(spacing: 6) {
      ZStack {
        if let highlight {
          Circle()
            .fill(
              RadialGradient(
                colors: [highlight.opacity(0.15), .clear],
                center: .center, startRadius: 0, endRadius: 30
              )
            )
        }
        Circle()
          .strokeBorder(
            highlight ?? Color.white.opacity(0.3),
            style: .init(lineWidth: 1, dash: dimmed ? [3, 3] : [])
          )
        Text(tier.label.uppercased())
          .font(.system(size: 11, weight: .semibold))
          .kerning(1)
          .foregroundStyle(highlight ?? Color.white.opacity(0.7))
      }
      .frame(width: 54, height: 54)
      .opacity(dimmed ? 0.55 : 1)

      Text("cap \(tier.softCap.map(String.init) ?? "∞")")
        .font(.system(.caption2, design: .monospaced))
        .kerning(0.3)
        .foregroundStyle(Color.white.opacity(0.45))
    }
  }

  private var explanation: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(visibilityText)
        .font(.system(size: 14))
        .kerning(-0.1)
        .lineSpacing(3)
        .foregroundStyle(Color.white.opacity(0.78))
      Text("Richiede conferma anche da \(proposal.person.name).")
        .font(.system(size: 12))
        .italic()
        .foregroundStyle(HaloTheme.textCaption)
    }
    .padding(.horizontal, 16).padding(.vertical, 14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .haloContentGlass(in: RoundedRectangle(cornerRadius: 16))
    .padding(.horizontal, 22)
  }

  private var actions: some View {
    HStack(spacing: 10) {
      Button(action: onDecline) {
        Text("Annulla")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(Color.white.opacity(0.75))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .haloGlass(in: RoundedRectangle(cornerRadius: 16), interactive: true)
      }
      .buttonStyle(.plain)

      Button(action: onAccept) {
        Text("Invia richiesta")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(
            LinearGradient(
              colors: [
                MoodPalette.auraColor(proposal.person.mood, l: 0.78),
                MoodPalette.auraColor(proposal.person.mood, l: 0.5),
              ],
              startPoint: .top, endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 16)
          )
          .shadow(color: MoodPalette.auraRing(proposal.person.mood, alpha: 0.5), radius: 12, y: 4)
          .haloGlass(in: RoundedRectangle(cornerRadius: 16), tint: MoodPalette.auraColor(proposal.person.mood, l: 0.55), interactive: true)
      }
      .buttonStyle(.plain)
      .layoutPriority(1.3)
    }
    .padding(.horizontal, 22).padding(.top, 14)
  }

  private var visibilityText: String {
    switch proposal.to {
    case .inner:  return "Potrà vedere tutti i tuoi post (anche audio) e le reazioni emotive in chiaro."
    case .close:  return "Potrà vedere foto, testo e audio. Reazioni in chiaro."
    case .orbit:  return "Vedrà foto e testo. Reazioni solo aggregate."
    case .nebula: return "Vedrà solo la tua presenza e la bio. Niente post."
    }
  }
}
