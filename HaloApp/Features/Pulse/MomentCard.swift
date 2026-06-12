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
  let person: HaloPersonNode
  /// Tap sull'intera card (apre HaloSpace).
  var onTap: () -> Void = {}
  /// Tap su una reazione.
  var onReact: (ReactionKind) -> Void = { _ in }

  /// Reazioni "live" che pingano transitoriamente sulla card. Aggiungere un
  /// nuovo `id` qui (UUID) avvia un'animazione concentrica e poi rimuove l'id.
  @State private var livePings: [UUID: ReactionKind] = [:]

  /// Micro-drift seed per dare un offset deterministico alla card (subliminale).
  private var driftSeed: Double {
    var h: UInt32 = 13
    for u in person.id.unicodeScalars { h = h &* 31 &+ u.value }
    return Double(h % 1000) / 1000
  }

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 18, paused: !person.hasActiveVibe)) { ctx in
      let t = ctx.date.timeIntervalSinceReferenceDate
      let dy = sin((t / (12.0 + driftSeed * 4)) * .pi * 2) * 1.2 // ±1.2pt
      let dx = cos((t / (16.0 + driftSeed * 5)) * .pi * 2) * 0.6 // ±0.6pt
      cardBody
        .offset(x: person.hasActiveVibe ? CGFloat(dx) : 0,
                y: person.hasActiveVibe ? CGFloat(dy) : 0)
    }
  }

  private var cardBody: some View {
    HStack(alignment: .top, spacing: 14) {
      portraitColumn

      VStack(alignment: .leading, spacing: 8) {
        header
        if person.hasActiveVibe {
          vibeNote
        }
        if person.lastPostAt != nil, let preview = postPreview {
          postWithDecayRing(preview)
          reactionsRow
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
    .haloContentGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard), stroke: borderColor)
    .contentShape(RoundedRectangle(cornerRadius: SwarmHalo.radiusCard))
    .overlay(alignment: .topTrailing) {
      ForEach(Array(livePings), id: \.key) { (id, kind) in
        LivePingView(kind: kind, color: MoodPalette.auraColor(person.mood, l: 0.85))
          .id(id)
          .padding(.trailing, 16)
          .padding(.top, 12)
      }
    }
    .onTapGesture(perform: onTap)
  }

  /// Trigger esterno per simulare un ping di reazione live.
  /// Quando `ReactionsService` realtime sarà cablato, chiamare questo da fuori.
  func triggerLivePing(_ kind: ReactionKind) {
    let id = UUID()
    livePings[id] = kind
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 900_000_000)
      livePings.removeValue(forKey: id)
    }
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
        .overlay(Circle().strokeBorder(person.tier.swarmHaloState.stroke, lineWidth: 0.8))
        .shadow(color: person.tier.swarmHaloState.glow, radius: 7)
      PortraitView(personId: person.id, size: portraitSize - 6, grayscale: true)
        .background(HaloTheme.portraitBacking, in: Circle())
    }
    .frame(width: 64, height: 64)
  }

  private var ringFill: Color {
    person.tier.swarmHaloState.ringFill
  }
  private var auraGlow: Color {
    person.hasActiveVibe ? MoodPalette.auraRing(person.mood, alpha: 0.55) : .clear
  }

  // MARK: - header

  private var header: some View {
    HStack(spacing: 8) {
      Text(person.name)
        .font(HaloType.serif(18, weight: .regular))
        .foregroundStyle(HaloInk.cream)
      tierBadge
      Spacer(minLength: 0)
      Text(timestampLabel)
        .font(HaloType.mono(11, weight: .medium))
        .kerning(1.0)
        .foregroundStyle(HaloInk.creamMute)
    }
  }

  private var tierBadge: some View {
    Text(person.tier.label)
      .font(HaloType.eyebrow(9))
      .kerning(1.8)
      .textCase(.uppercase)
      .foregroundStyle(person.tier.swarmHaloState.accent)
      .padding(.horizontal, 7)
      .padding(.vertical, 2.5)
      .background(person.tier.swarmHaloState.badgeFill, in: Capsule())
      .overlay(Capsule().strokeBorder(person.tier.swarmHaloState.stroke, lineWidth: 0.5))
  }

  // MARK: - vibe note

  private var vibeNote: some View {
    HStack(spacing: 8) {
      moodChip
      if !person.note.isEmpty {
        Text("\u{201C}\(person.note)\u{201D}")
          .font(HaloType.serif(15, weight: .regular))
          .foregroundStyle(HaloInk.creamLow)
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
        .font(HaloType.ui(11, weight: .medium))
        .foregroundStyle(HaloInk.creamLow)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(SwarmHalo.creamWhisper, in: Capsule())
    .overlay(Capsule().strokeBorder(SwarmHalo.strokeSoft, lineWidth: 0.5))
  }

  // MARK: - post inline + decay

  /// Tipo + caption di anteprima per il post inline. nil = non mostrare slot.
  private struct PostPreview {
    enum Kind {
      case photo, text, audio

      init(_ kind: PostKind) {
        switch kind {
        case .photo: self = .photo
        case .text: self = .text
        case .audio: self = .audio
        }
      }
    }

    let kind: Kind
    let caption: String
    let mediaPath: String?
  }

  private var postPreview: PostPreview? {
    guard person.lastPostAt != nil else { return nil }
    let kind = PostPreview.Kind(person.lastPostKind ?? .text)
    let caption = person.lastPostCaption ?? ""
    return PostPreview(kind: kind, caption: caption, mediaPath: person.lastPostMediaPath)
  }

  /// Decay 0..1 del ring intorno al post: 1 = appena postato, 0 = scaduto.
  private var postDecay: Double {
    guard let createdAt = person.lastPostAt else { return 0 }
    let expiresAt = person.lastPostExpiresAt ?? createdAt.addingTimeInterval(72 * 3600)
    let total = expiresAt.timeIntervalSince(createdAt)
    let remaining = expiresAt.timeIntervalSince(Date.now)
    guard total > 0 else { return 0 }
    return min(max(remaining / total, 0), 1)
  }

  private func postWithDecayRing(_ preview: PostPreview) -> some View {
    HStack(alignment: .top, spacing: 10) {
      // Decay ring: anello sottile che si svuota nelle 72h.
      ZStack {
        Circle()
          .stroke(SwarmHalo.strokeRest, lineWidth: 1.5)
          .frame(width: 22, height: 22)
        Circle()
          .trim(from: 0, to: postDecay)
          .stroke(MoodPalette.auraColor(person.mood, l: 0.78),
                  style: .init(lineWidth: 1.8, lineCap: .round))
          .rotationEffect(.degrees(-90))
          .frame(width: 22, height: 22)
        Image(systemName: postIcon(preview.kind))
          .font(HaloType.system(9, weight: .semibold))
          .foregroundStyle(SwarmHalo.inkSecondary)
      }
      .accessibilityLabel("decay")

      // Body inline a seconda del tipo.
      Group {
        switch preview.kind {
        case .photo: photoPreview(preview)
        case .text:  textPreview(preview)
        case .audio: audioPreview(preview)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.top, 4)
  }

  private func postIcon(_ k: PostPreview.Kind) -> String {
    switch k {
    case .photo: return "photo.fill"
    case .text:  return "text.alignleft"
    case .audio: return "waveform"
    }
  }

  private func photoPreview(_ p: PostPreview) -> some View {
    ZStack(alignment: .bottomLeading) {
      StorageImageView(path: p.mediaPath) {
        photoPreviewPlaceholder
      }
      if !p.caption.isEmpty {
        Text(p.caption)
          .font(HaloType.serif(13, weight: .regular))
          .foregroundStyle(HaloInk.cream)
          .padding(.horizontal, 10).padding(.vertical, 6)
          .background(SwarmHalo.absoluteBlack.opacity(0.25))
          .clipShape(Capsule())
          .padding(8)
      } else if p.mediaPath != nil {
        Text("foto")
          .haloEyebrow(HaloInk.creamMute, size: 7.5, tracking: 1.5)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(SwarmHalo.absoluteBlack.opacity(0.22))
          .clipShape(Capsule())
          .padding(8)
      }
    }
    .frame(height: 96)
    .clipShape(RoundedRectangle(cornerRadius: SwarmHalo.radiusCard))
  }

  private var photoPreviewPlaceholder: some View {
    LinearGradient(
      colors: [
        MoodPalette.auraColor(person.mood, l: 0.50),
        MoodPalette.auraColor(person.mood, l: 0.25),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private func textPreview(_ p: PostPreview) -> some View {
    Text(p.caption)
      .font(HaloType.ui(13, weight: .regular))
      .foregroundStyle(HaloInk.cream)
      .lineLimit(3)
      .padding(.horizontal, 12).padding(.vertical, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .haloContentGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard * 2))
  }

  private func audioPreview(_ p: PostPreview) -> some View {
    HStack(spacing: 10) {
      StorageAudioPlaybackButton(
        path: p.mediaPath,
        accentMood: person.mood,
        size: 28,
        iconSize: 10,
        foregroundColor: SwarmHalo.background
      )
      HStack(spacing: 2) {
        ForEach(0..<18, id: \.self) { i in
          Capsule()
            .fill(SwarmHalo.ink.opacity(0.20 + (Double(i) / 22) * 0.5))
            .frame(width: 2.5, height: CGFloat(6 + abs(sin(Double(i) * 1.3)) * 14))
        }
      }
      .frame(height: 22)
      Spacer(minLength: 0)
      if !p.caption.isEmpty {
        Text(p.caption)
          .font(HaloType.ui(10, weight: .medium))
          .foregroundStyle(HaloInk.creamMute)
          .lineLimit(1)
      }
    }
    .padding(.horizontal, 12).padding(.vertical, 8)
    .haloContentGlass(in: RoundedRectangle(cornerRadius: 12))
  }

  // MARK: - reactions (tier-aware)

  /// Aggregati reali del post corrente. Vuoto = nessuna reazione da mostrare.
  private var reactionTallies: [HaloReactionTally] {
    person.lastPostReactionTallies
  }

  private var canSeeActors: Bool {
    person.tier == .inner || person.tier == .close
  }

  private var reactionsRow: some View {
    HStack(spacing: 10) {
      ForEach(reactionTallies, id: \.kind) { tally in
        Button {
          onReact(tally.kind)
        } label: {
          HStack(spacing: 5) {
            ReactionGlyph(kind: tally.kind, size: 14, color: SwarmHalo.inkSecondary)
            if canSeeActors, let labels = tally.actorLabels, !labels.isEmpty {
              Text(labels.prefix(2).map { "@\($0)" }.joined(separator: " "))
                .font(HaloType.ui(10, weight: .medium))
                .foregroundStyle(HaloInk.creamMute)
              if tally.count > 2 {
                Text("+\(tally.count - 2)")
                  .font(HaloType.mono(10, weight: .medium))
                  .foregroundStyle(HaloInk.creamMute)
              }
            } else {
              Text("\(tally.count)")
                .font(HaloType.mono(10, weight: .medium))
                .foregroundStyle(HaloInk.creamMute)
            }
          }
          .padding(.horizontal, 6).padding(.vertical, 4)
          .haloGlass(in: Capsule(), interactive: true)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.top, 6)
  }

  // MARK: - warning border (post in scadenza < 2h)

  /// Tempo residuo prima della scadenza del post.
  private var hoursUntilExpiry: Double? {
    guard let t = person.lastPostAt else { return nil }
    let remaining = (person.lastPostExpiresAt ?? t.addingTimeInterval(72 * 3600)).timeIntervalSince(Date.now)
    return remaining > 0 ? remaining / 3600 : nil
  }

  private var isExpiringSoon: Bool {
    if let h = hoursUntilExpiry { return h < 2 }
    return false
  }

  private var borderColor: Color {
    if isExpiringSoon {
      return SwarmHalo.attention.opacity(0.86)
    }
    return HaloTheme.hairlineSoft
  }

  private var borderWidth: CGFloat {
    isExpiringSoon ? 1.2 : 0.5
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

// MARK: - LivePingView

/// Cerchio che si espande e svanisce; usato per "ping" reattivi live.
private struct LivePingView: View {
  let kind: ReactionKind
  let color: Color
  @State private var scale: CGFloat = 0.4
  @State private var opacity: Double = 0.9

  var body: some View {
    ZStack {
      Circle()
        .stroke(color.opacity(opacity * 0.6), lineWidth: 1.5)
        .frame(width: 36, height: 36)
        .scaleEffect(scale)
      ReactionGlyph(kind: kind, size: 16, color: color)
        .opacity(opacity)
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.85)) {
        scale = 1.7
        opacity = 0
      }
    }
  }
}

#Preview {
  ZStack {
    SwarmHalo.background
    VStack(spacing: 12) {
      MomentCard(person: SeedPeople.all[0])
      MomentCard(person: SeedPeople.all[6])
      MomentCard(person: SeedPeople.all[10])
    }
    .padding()
  }
}
