import SwiftUI
import HaloShared

/// Unità base del Pulse feed: una persona col suo stato attuale.
/// Layer:
///  1. portrait con aura mood-color (pulsante se vibe attiva)
///  2. header: name + tier badge + timestamp
///  3. (opz.) vibe note → mood chip + nota testuale
///  4. (opz.) ultimo post inline + decay ring + reactions
///
/// Card senza post = valida (presenza pura).
struct MomentCard: View {
  let person: DemoPerson
  /// Tap sull'intera card (apre HaloSpace).
  var onTap: () -> Void = {}

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      portraitColumn

      VStack(alignment: .leading, spacing: 8) {
        header
        if person.hasActiveVibe {
          vibeNote
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
    .background(
      RoundedRectangle(cornerRadius: 22)
        .fill(.white.opacity(0.04))
        .overlay(
          RoundedRectangle(cornerRadius: 22)
            .strokeBorder(HaloTheme.hairlineSoft, lineWidth: 0.5)
        )
    )
    .contentShape(RoundedRectangle(cornerRadius: 22))
    .onTapGesture(perform: onTap)
  }

  // MARK: - portrait

  private var portraitColumn: some View {
    let portraitSize: CGFloat = 56

    return ZStack {
      // aura pulsante solo se vibe attiva
      TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !person.hasActiveVibe)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / 3.4) * .pi * 2)
        let opacity = person.hasActiveVibe ? (0.55 + 0.20 * phase) : 0.30
        Circle()
          .fill(
            RadialGradient(
              colors: [auraGlow, .clear],
              center: .center, startRadius: 0, endRadius: portraitSize * 0.95
            )
          )
          .frame(width: portraitSize * 1.5, height: portraitSize * 1.5)
          .opacity(opacity)
      }
      .allowsHitTesting(false)

      // ring + portrait
      Circle()
        .fill(ringFill)
        .frame(width: portraitSize, height: portraitSize)
        .shadow(color: auraGlow, radius: 7)
      PortraitView(personId: person.id, size: portraitSize - 6)
        .background(HaloTheme.portraitBacking, in: Circle())
    }
    .frame(width: 64, height: 64)
  }

  private var ringFill: Color {
    person.hasActiveVibe ? MoodPalette.auraColor(person.mood, l: 0.72) : Color.white.opacity(0.18)
  }
  private var auraGlow: Color {
    person.hasActiveVibe ? MoodPalette.auraRing(person.mood, alpha: 0.55) : Color.white.opacity(0.10)
  }

  // MARK: - header

  private var header: some View {
    HStack(spacing: 8) {
      Text(person.name)
        .font(.system(size: 15, weight: .semibold))
        .kerning(-0.2)
        .foregroundStyle(.white)
      tierBadge
      Spacer(minLength: 0)
      Text(timestampLabel)
        .font(HaloTheme.mono)
        .kerning(0.3)
        .foregroundStyle(HaloTheme.textCaption)
    }
  }

  private var tierBadge: some View {
    Text(person.tier.label.lowercased())
      .font(.system(size: 10, weight: .semibold, design: .rounded))
      .kerning(0.4)
      .textCase(.uppercase)
      .foregroundStyle(.white.opacity(0.78))
      .padding(.horizontal, 7)
      .padding(.vertical, 2.5)
      .background(.white.opacity(0.06), in: Capsule())
      .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
  }

  // MARK: - vibe note

  private var vibeNote: some View {
    HStack(spacing: 8) {
      moodChip
      if !person.note.isEmpty {
        Text("\u{201C}\(person.note)\u{201D}")
          .font(.system(size: 13))
          .italic()
          .foregroundStyle(Color.white.opacity(0.62))
          .lineLimit(2)
      }
    }
  }

  private var moodChip: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(MoodPalette.auraColor(person.mood, l: 0.82))
        .frame(width: 7, height: 7)
        .shadow(color: MoodPalette.auraRing(person.mood, alpha: 0.55), radius: 3)
      Text(person.mood.rawValue)
        .font(.system(size: 11, weight: .medium))
        .kerning(0.1)
        .foregroundStyle(Color.white.opacity(0.82))
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(.white.opacity(0.05), in: Capsule())
    .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5))
  }

  /// "Adesso" se < 30 min, altrimenti "Xm" / "Xh" / "Xg".
  private var timestampLabel: String {
    guard let t = person.lastPostAt else {
      return person.hasActiveVibe ? "vibe" : "—"
    }
    let s = Date.now.timeIntervalSince(t)
    if s < 30 * 60 { return "adesso" }
    if s < 3600 { return "\(Int(s / 60))m" }
    if s < 24 * 3600 { return "\(Int(s / 3600))h" }
    return "\(Int(s / (24 * 3600)))g"
  }
}

#Preview {
  ZStack {
    Color.black
    VStack(spacing: 12) {
      MomentCard(person: SeedPeople.all[0])
      MomentCard(person: SeedPeople.all[6])
      MomentCard(person: SeedPeople.all[10])
    }
    .padding()
  }
}
