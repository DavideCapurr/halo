import SwiftUI
import HaloShared

/// Pulse feed v2 — editorial / chat-post hybrid.
///
/// La sezione "stanotte" che esisteva prima è ora una **headline dinamica**
/// (vedi `HaloMoment.current()`) che cambia in base all'ora reale: di notte
/// è "Stanotte.", di mattina "Stamattina.", di pomeriggio "Oggi.", ecc.
///
/// Ogni riga ibrida chat e post:
///   - tile monogramma (lettera serif italic) + portrait pulsante
///   - nome serif italic + mood dot + ago in mono
///   - quote vibe in italic serif (la "voce" della persona)
///   - se ha un post recente: mini-anteprima inline (foto/testo/audio)
///   - barra azioni rapide chat-style (sussurra, amplifica, eco)
struct PulseFeedView: View {
  @State private var vm = FeedViewModel()
  /// Tap su una card → apri HaloSpace della persona.
  var onPersonTap: (DemoPerson) -> Void = { _ in }

  /// Dynamic moment — recalcolato quando il view appare.
  @State private var moment: HaloMoment = .current()

  var body: some View {
    ZStack {
      backgroundLayer

      ScrollView {
        VStack(spacing: 0) {
          headerSection
            .padding(.horizontal, 22)
            .padding(.top, 12)

          pulseStats
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 6)

          // Adesso section — only if anyone is actively posting.
          if !vm.adessoItems.isEmpty {
            sectionHeader("Adesso", count: vm.adessoItems.count, accent: true)
              .padding(.horizontal, 22)
              .padding(.top, 22)
            ForEach(vm.adessoItems) { p in
              ChatPostRow(person: p, accent: true, onTap: { onPersonTap(p) })
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
            }
          }

          ForEach(vm.sections, id: \.0) { (section, items) in
            sectionHeader(section.title, count: items.count)
              .padding(.horizontal, 22)
              .padding(.top, 26)
            ForEach(items) { p in
              ChatPostRow(person: p, onTap: { onPersonTap(p) })
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
            }
          }

          Spacer().frame(height: 40)
        }
        .padding(.bottom, 80)
      }
      .scrollIndicators(.hidden)
    }
    .task {
      moment = .current()
      await vm.load()
    }
  }

  // MARK: - background

  private var backgroundLayer: some View {
    ZStack {
      DeepSpaceBackground()
      // Single warm spot — late-night lamp; tinted dal mood dominante.
      let dominant = vm.dominantMood() ?? .warm
      RadialGradient(
        colors: [MoodPalette.auraRing(dominant, alpha: 0.18), .clear],
        center: UnitPoint(x: 0.15, y: 0.92),
        startRadius: 0, endRadius: 460
      )
      .ignoresSafeArea()
      .animation(.easeInOut(duration: 0.6), value: dominant)
    }
  }

  // MARK: - header (editorial dynamic)

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Text(moment.eyebrow)
          .haloEyebrow(HaloInk.creamMute, size: 9.5, tracking: 2.6)
        Rectangle().fill(HaloInk.creamLine).frame(height: 0.5)
      }
      .padding(.bottom, 4)

      Text(moment.headline + ".")
        .font(HaloType.serif(40, weight: .regular))
        .foregroundStyle(HaloInk.cream)
        .kerning(-0.6)
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Text(moment.subtitle)
        .font(HaloType.serif(15))
        .foregroundStyle(HaloInk.creamLow)
    }
  }

  // MARK: - stats strip

  private var pulseStats: some View {
    let activeCount = vm.people.filter(\.hasActiveVibe).count
    let nowCount = vm.adessoItems.count
    let dominant = vm.dominantMood()

    return HStack(alignment: .center, spacing: 0) {
      insightCell(label: "presenze", value: String(format: "%02d", activeCount))
      separator
      insightCell(label: "adesso", value: String(format: "%02d", nowCount), accent: nowCount > 0)
      separator
      moodCell(dominant)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 18)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
    )
  }

  private var separator: some View {
    Rectangle()
      .fill(HaloInk.creamLine)
      .frame(width: 0.5, height: 28)
  }

  private func insightCell(label: String, value: String, accent: Bool = false) -> some View {
    VStack(spacing: 4) {
      Text(value)
        .font(HaloType.mono(18, weight: .semibold))
        .foregroundStyle(accent ? HaloInk.bronze : HaloInk.cream)
        .kerning(-0.2)
      Text(label)
        .haloEyebrow(HaloInk.creamMute, size: 8, tracking: 2.4)
    }
    .frame(maxWidth: .infinity)
  }

  private func moodCell(_ mood: Mood?) -> some View {
    VStack(spacing: 4) {
      HStack(spacing: 5) {
        Circle()
          .fill(mood.map { MoodPalette.auraColor($0, l: 0.78) } ?? HaloInk.creamHair)
          .frame(width: 8, height: 8)
          .shadow(color: mood.map { MoodPalette.auraRing($0, alpha: 0.55) } ?? .clear, radius: 4)
        Text(mood?.rawValue ?? "—")
          .font(HaloType.serif(15))
          .foregroundStyle(HaloInk.cream)
      }
      Text("vibe diffusa")
        .haloEyebrow(HaloInk.creamMute, size: 8, tracking: 2.4)
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - section header

  private func sectionHeader(_ title: String, count: Int, accent: Bool = false) -> some View {
    HStack(spacing: 10) {
      Text(title)
        .haloEyebrow(accent ? HaloInk.bronze : HaloInk.creamMute, size: 9.5, tracking: 3.0)
      Rectangle()
        .fill(accent ? HaloInk.bronzeSoft : HaloInk.creamLine)
        .frame(height: 0.5)
      Text(String(format: "%02d", count))
        .font(HaloType.mono(9, weight: .medium))
        .kerning(2.0)
        .foregroundStyle(accent ? HaloInk.bronze : HaloInk.creamMute)
    }
    .padding(.bottom, 6)
  }
}

// MARK: - ChatPostRow (the hybrid chat + post unit)

private struct ChatPostRow: View {
  let person: DemoPerson
  var accent: Bool = false
  var onTap: () -> Void = {}

  private var ago: String {
    guard let t = person.lastPostAt else {
      return person.hasActiveVibe ? "vibe" : "—"
    }
    let s = Date.now.timeIntervalSince(t)
    if s < 30 * 60 { return "adesso" }
    if s < 3600 { return "\(Int(s / 60))m" }
    if s < 24 * 3600 { return "\(Int(s / 3600))h" }
    return "\(Int(s / (24 * 3600)))g"
  }

  /// Dove era la persona — pseudo-state derivato dal mood. Demo only.
  private var contextLine: String? {
    guard person.hasActiveVibe else { return nil }
    switch person.mood {
    case .warm:     return "casa · luce calda"
    case .focused:  return "biblio · cuffie"
    case .wild:     return "in giro · dopocena"
    case .chill:    return "divano · tisana"
    case .electric: return "alza il volume"
    case .blue:     return "fuori, da solo"
    case .soft:     return "in pigiama"
    case .lost:     return "non risponde"
    }
  }

  /// Posts a deterministic preview type so demo content varies.
  private struct Preview {
    enum Kind { case photo, text, audio }
    let kind: Kind
    let body: String
  }

  private var preview: Preview? {
    guard person.lastPostAt != nil else { return nil }
    var h: UInt32 = 5381
    for u in person.id.unicodeScalars { h = h &* 33 &+ u.value }
    let bucket = h % 100
    let kind: Preview.Kind = (bucket < 35) ? .photo : (bucket < 85) ? .text : .audio
    let body = person.note.isEmpty
      ? (kind == .text ? "qualcosa di non detto" : "")
      : person.note
    return Preview(kind: kind, body: body)
  }

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .center, spacing: 12) {
          avatar
          VStack(alignment: .leading, spacing: 4) {
            headerLine
            presenceLine
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        if !person.note.isEmpty && person.hasActiveVibe {
          messageBubble
        }

        if let p = preview {
          postAttachment(p)
        }

        pulseFooter
      }
      .padding(14)
      .background(rowBackground)
      .overlay(rowBorder)
    }
    .buttonStyle(.plain)
  }

  // MARK: avatar

  private var avatar: some View {
    ZStack {
      // Pulse aura — only if vibe attiva.
      TimelineView(.animation(minimumInterval: 1.0 / 18, paused: !person.hasActiveVibe)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / 3.4) * .pi * 2)
        let opacity = person.hasActiveVibe ? (0.50 + 0.18 * phase) : 0.18
        Circle()
          .fill(
            RadialGradient(
              colors: [MoodPalette.auraRing(person.mood, alpha: 0.55), .clear],
              center: .center, startRadius: 0, endRadius: 38
            )
          )
          .frame(width: 64, height: 64)
          .opacity(opacity)
      }
      .allowsHitTesting(false)

      Circle()
        .fill(person.hasActiveVibe ? MoodPalette.auraColor(person.mood, l: 0.72) : HaloInk.creamHair)
        .frame(width: 50, height: 50)

      PortraitView(personId: person.id, size: 44)
        .background(HaloTheme.portraitBacking, in: Circle())

      // mood dot — top right
      Circle()
        .fill(MoodPalette.auraColor(person.mood, l: 0.78))
        .frame(width: 9, height: 9)
        .overlay(Circle().stroke(HaloInk.nightSurface, lineWidth: 1.5))
        .offset(x: 18, y: -18)
    }
    .frame(width: 50, height: 50)
  }

  // MARK: header

  private var headerLine: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text(person.name.lowercased())
        .font(HaloType.serif(20))
        .foregroundStyle(HaloInk.cream)
        .kerning(-0.3)
      Circle()
        .fill(MoodPalette.auraColor(person.mood, l: 0.78))
        .frame(width: 5, height: 5)
      Text(person.mood.rawValue)
        .font(HaloType.mono(8.5, weight: .medium))
        .kerning(1.2)
        .textCase(.uppercase)
        .foregroundStyle(HaloInk.creamMute)
      Spacer(minLength: 0)
      Text(ago)
        .font(HaloType.mono(9, weight: .medium))
        .kerning(0.6)
        .textCase(.uppercase)
        .foregroundStyle(accent || ago == "adesso" ? HaloInk.bronze : HaloInk.creamMute)
    }
  }

  private var presenceLine: some View {
    HStack(spacing: 7) {
      Text("@\(person.handle)")
      Text("·")
      Text(person.tier.label.lowercased())
      if let ctx = contextLine {
        Text("·")
        Text(ctx)
      }
    }
    .font(HaloType.ui(11.5, weight: .medium))
    .foregroundStyle(HaloInk.creamMute)
    .lineLimit(1)
  }

  // MARK: message bubble

  private var messageBubble: some View {
    HStack(alignment: .bottom, spacing: 10) {
      Text("\u{201C}\(person.note)\u{201D}")
        .font(HaloType.serif(16))
        .foregroundStyle(HaloInk.cream)
        .lineSpacing(2)
        .lineLimit(4)
      Spacer(minLength: 0)
      Text("vibe")
        .haloEyebrow(HaloInk.creamMute, size: 7.5, tracking: 1.5)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(HaloInk.creamWhisper)
    )
    .overlay(alignment: .leading) {
      RoundedRectangle(cornerRadius: 1)
        .fill(MoodPalette.auraColor(person.mood, l: 0.68))
        .frame(width: 2)
        .padding(.vertical, 10)
    }
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(HaloInk.creamLine, lineWidth: 0.5)
    )
    .fixedSize(horizontal: false, vertical: true)
  }

  // MARK: post attachment

  private func postAttachment(_ p: Preview) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: attachmentIcon(p.kind))
          .font(.system(size: 10, weight: .semibold))
        Text(attachmentLabel(p.kind))
          .haloEyebrow(HaloInk.creamMute, size: 8, tracking: 1.8)
        Rectangle()
          .fill(HaloInk.creamLine)
          .frame(height: 0.5)
      }
      .foregroundStyle(HaloInk.creamMute)

      postBubble(p)
    }
    .padding(10)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(accent ? HaloInk.bronzeSoft : HaloInk.creamHair, lineWidth: accent ? 0.8 : 0.5)
    )
  }

  @ViewBuilder
  private func postBubble(_ p: Preview) -> some View {
    switch p.kind {
    case .photo:
      ZStack(alignment: .bottomLeading) {
        LinearGradient(
          colors: [
            MoodPalette.auraColor(person.mood, l: 0.42),
            MoodPalette.auraColor(person.mood, l: 0.20),
          ],
          startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .frame(height: 88)
        // diagonal hatch — adds subtle texture, "old photo" feel
        Canvas { ctx, size in
          ctx.opacity = 0.10
          var path = Path()
          let step: CGFloat = 7
          var x: CGFloat = -size.height
          while x < size.width {
            path.move(to: CGPoint(x: x, y: size.height))
            path.addLine(to: CGPoint(x: x + size.height, y: 0))
            x += step
          }
          ctx.stroke(path, with: .color(.white), lineWidth: 0.5)
        }
        .frame(height: 88)
        if !p.body.isEmpty {
          Text("\u{201C}\(p.body)\u{201D}")
            .font(HaloType.serif(14))
            .foregroundStyle(Color.white.opacity(0.95))
            .padding(.horizontal, 12).padding(.bottom, 10)
            .lineLimit(2)
        }
      }
      .frame(height: 88)
      .clipShape(RoundedRectangle(cornerRadius: 14))
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .strokeBorder(HaloInk.creamLine, lineWidth: 0.5)
      )

    case .text:
      // Looks like a chat bubble, reads like an editorial quote.
      Text(p.body)
        .font(HaloType.ui(13.5, weight: .regular))
        .foregroundStyle(HaloInk.cream)
        .kerning(-0.05)
        .lineSpacing(3)
        .lineLimit(3)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: 14)
            .fill(HaloInk.nightSurface.opacity(0.36))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .strokeBorder(HaloInk.creamLine, lineWidth: 0.5)
        )

    case .audio:
      HStack(spacing: 10) {
        ZStack {
          Circle()
            .fill(MoodPalette.auraColor(person.mood, l: 0.7))
          Image(systemName: "play.fill")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .offset(x: 1)
        }
        .frame(width: 30, height: 30)

        HStack(spacing: 2) {
          ForEach(0..<22, id: \.self) { i in
            Capsule()
              .fill(Color.white.opacity(i < 10 ? 0.78 : 0.22))
              .frame(width: 2, height: CGFloat(5 + abs(sin(Double(i) * 1.3)) * 14))
          }
        }
        .frame(height: 22)

        Spacer()
        Text("0:14")
          .font(HaloType.mono(9, weight: .medium))
          .kerning(0.4)
          .foregroundStyle(HaloInk.creamMute)
      }
      .padding(.horizontal, 12).padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 14)
          .fill(HaloInk.nightSurface.opacity(0.36))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .strokeBorder(HaloInk.creamHair, lineWidth: 0.5)
      )
    }
  }

  // MARK: quick actions (chat-style)

  private var pulseFooter: some View {
    HStack(spacing: 8) {
      footerChip(icon: "bubble.left", label: "rispondi")
      footerChip(icon: "wave.3.right", label: "eco")
      Spacer()
      Text(ago == "adesso" ? "live" : "apri")
        .haloEyebrow(ago == "adesso" ? HaloInk.bronze : HaloInk.creamMute, size: 8, tracking: 1.5)
    }
    .padding(.top, 1)
  }

  private func footerChip(icon: String, label: String) -> some View {
    HStack(spacing: 5) {
      Image(systemName: icon)
        .font(.system(size: 10, weight: .medium))
      Text(label)
        .font(HaloType.mono(9, weight: .medium))
        .kerning(0.6)
        .textCase(.uppercase)
    }
    .foregroundStyle(HaloInk.creamLow)
    .padding(.horizontal, 9)
    .padding(.vertical, 5)
    .background(
      Capsule().fill(HaloInk.creamWhisper)
    )
    .overlay(Capsule().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
  }

  private func attachmentIcon(_ kind: Preview.Kind) -> String {
    switch kind {
    case .photo: return "photo"
    case .text: return "text.alignleft"
    case .audio: return "waveform"
    }
  }

  private func attachmentLabel(_ kind: Preview.Kind) -> String {
    switch kind {
    case .photo: return "post foto"
    case .text: return "post testo"
    case .audio: return "nota audio"
    }
  }

  // MARK: row bg / border

  private var rowBackground: some View {
    RoundedRectangle(cornerRadius: 22)
      .fill(.ultraThinMaterial)
      .overlay(
        RoundedRectangle(cornerRadius: 22)
          .fill(
            LinearGradient(
              colors: [
                Color.white.opacity(0.04),
                Color.clear,
                Color.black.opacity(0.10),
              ],
              startPoint: .top, endPoint: .bottom
            )
          )
      )
  }

  private var rowBorder: some View {
    RoundedRectangle(cornerRadius: 22)
      .strokeBorder(accent ? HaloInk.bronzeSoft : HaloInk.creamHair, lineWidth: accent ? 0.8 : 0.5)
  }
}

#Preview {
  PulseFeedView()
    .preferredColorScheme(.dark)
}
