import SwiftUI
import HaloShared

/// Pulse: feed di drop spontanei.
/// Il default resta il Cerchio, ma "Tutti" apre il flusso delle proprie orbite
/// senza trasformare la schermata in una chat di gruppo.
struct PulseFeedView: View {
  @State private var vm = FeedViewModel()
  @State private var moment: HaloMoment = .current()
  @State private var scope: PulseScope = .cerchio
  @State private var draft: String = ""
  @State private var isDraftOpen: Bool = false

  var onPersonTap: (DemoPerson) -> Void = { _ in }

  var body: some View {
    ZStack {
      backgroundLayer

      ScrollView {
        LazyVStack(spacing: 0) {
          headerSection
            .padding(.horizontal, 22)
            .padding(.top, 12)

          PulseScopePicker(selection: $scope)
            .padding(.horizontal, 22)
            .padding(.top, 16)

          pulseStats
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 12)

          ForEach(vm.pulseEventGroups(in: scope)) { group in
            momentSeparator(group)
              .padding(.horizontal, 22)
              .padding(.top, group.moment == .adesso ? 8 : 22)
              .padding(.bottom, 10)

            ForEach(group.events) { event in
              PulseDropCard(event: event, onPersonTap: { onPersonTap(event.person) })
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
            }
          }

          Spacer().frame(height: 32)
        }
        .padding(.bottom, 118)
      }
      .scrollIndicators(.hidden)
    }
    .safeAreaInset(edge: .bottom) {
      PulseDropDock(
        scope: scope,
        text: $draft,
        isDraftOpen: $isDraftOpen,
        onPublish: publishDraft,
        onQuickDrop: addQuickDrop
      )
      .padding(.horizontal, 14)
      .padding(.bottom, 8)
    }
    .task {
      moment = .current()
      await vm.load()
    }
  }

  private var backgroundLayer: some View {
    ZStack {
      DeepSpaceBackground()
      let dominant = vm.dominantMood(in: scope) ?? .warm
      RadialGradient(
        colors: [MoodPalette.auraRing(dominant, alpha: 0.14), .clear],
        center: UnitPoint(x: 0.14, y: 0.88),
        startRadius: 0,
        endRadius: 470
      )
      .ignoresSafeArea()
      .animation(.easeInOut(duration: 0.6), value: dominant)
    }
  }

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Text(moment.eyebrow)
          .haloEyebrow(HaloInk.creamMute, size: 9.5, tracking: 2.6)
        Rectangle().fill(HaloInk.creamLine).frame(height: 0.5)
      }
      .padding(.bottom, 2)

      Text(moment.headline + ".")
        .font(HaloType.serif(36, weight: .regular))
        .foregroundStyle(HaloInk.cream)
        .kerning(-0.5)
        .lineLimit(1)
        .minimumScaleFactor(0.72)

      Text(scope == .cerchio ? "drop spontanei dal tuo cerchio" : "tutti i segnali dalle tue orbite")
        .font(HaloType.serif(15))
        .foregroundStyle(HaloInk.creamLow)
        .animation(.easeInOut(duration: 0.18), value: scope)
    }
  }

  private var pulseStats: some View {
    let activeCount = vm.pulsePeople(in: scope).filter(\.hasActiveVibe).count
    let eventCount = vm.pulseEvents(in: scope).count
    let liveCount = vm.liveEventCount(in: scope)

    return HStack(alignment: .center, spacing: 0) {
      statCell(scope.title.lowercased(), value: String(format: "%02d", vm.pulsePeople(in: scope).count))
      separator
      statCell("live", value: String(format: "%02d", liveCount), accent: liveCount > 0)
      separator
      statCell("drop", value: String(format: "%02d", eventCount), accent: activeCount > 0)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
    )
  }

  private var separator: some View {
    Rectangle()
      .fill(HaloInk.creamLine)
      .frame(width: 0.5, height: 28)
  }

  private func statCell(_ label: String, value: String, accent: Bool = false) -> some View {
    VStack(spacing: 4) {
      Text(value)
        .font(HaloType.mono(18, weight: .semibold))
        .foregroundStyle(accent ? HaloInk.bronze : HaloInk.cream)
      Text(label)
        .haloEyebrow(HaloInk.creamMute, size: 8, tracking: 2.4)
    }
    .frame(maxWidth: .infinity)
  }

  private func momentSeparator(_ group: PulseEventGroup) -> some View {
    HStack(spacing: 10) {
      Text(group.moment.title)
        .haloEyebrow(group.moment == .adesso ? HaloInk.bronze : HaloInk.creamMute, size: 9.5, tracking: 3.0)
      Rectangle()
        .fill(group.moment == .adesso ? HaloInk.bronzeSoft : HaloInk.creamLine)
        .frame(height: 0.5)
      Text(String(format: "%02d", group.events.count))
        .font(HaloType.mono(9, weight: .medium))
        .kerning(2.0)
        .foregroundStyle(group.moment == .adesso ? HaloInk.bronze : HaloInk.creamMute)
    }
  }

  private func publishDraft() {
    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    vm.addLocalMessage(text, audience: scope)
    draft = ""
    withAnimation(.easeInOut(duration: 0.18)) {
      isDraftOpen = false
    }
  }

  private func addQuickDrop(_ type: PulseDropDock.DropType) {
    switch type {
    case .note:
      withAnimation(.easeInOut(duration: 0.18)) {
        isDraftOpen = true
      }
    case .photo:
      vm.addLocalPlaceholder(.photoPost("appena successo"), audience: scope)
    case .audio:
      vm.addLocalPlaceholder(.audioPost("voice note · 0:14"), audience: scope)
    case .vibe:
      vm.addLocalPlaceholder(.vibe(draft.isEmpty ? "sono qui" : draft), audience: scope)
      draft = ""
      isDraftOpen = false
    }
  }
}

private struct PulseScopePicker: View {
  @Binding var selection: PulseScope

  var body: some View {
    Picker("Feed", selection: $selection) {
      ForEach(PulseScope.allCases) { scope in
        Text(scope.title).tag(scope)
      }
    }
    .pickerStyle(.segmented)
    .tint(HaloInk.bronze)
  }
}

private struct PulseDropCard: View {
  let event: PulseEvent
  var onPersonTap: () -> Void = {}

  var body: some View {
    switch event.kind {
    case .moodChange:
      systemEvent
    default:
      Button(action: onPersonTap) {
        VStack(alignment: .leading, spacing: 12) {
          header
          content
          actionRow
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .overlay(cardBorder)
      }
      .buttonStyle(.plain)
    }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 11) {
      avatar

      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 7) {
          Text(event.isMine ? "tu" : event.person.name.lowercased())
            .font(HaloType.serif(18))
            .foregroundStyle(HaloInk.cream)
          Circle()
            .fill(MoodPalette.auraColor(event.person.mood, l: 0.78))
            .frame(width: 5, height: 5)
          Text(event.person.mood.rawValue)
            .haloEyebrow(HaloInk.creamMute, size: 7.5, tracking: 1.5)
        }
        Text("@\(event.person.handle) · \(event.person.tier.label.lowercased())")
          .font(HaloType.ui(11, weight: .medium))
          .foregroundStyle(HaloInk.creamMute)
          .lineLimit(1)
      }

      Spacer(minLength: 10)

      VStack(alignment: .trailing, spacing: 5) {
        Text(timeLabel(event.createdAt))
          .font(HaloType.mono(9, weight: .medium))
          .kerning(0.7)
          .textCase(.uppercase)
          .foregroundStyle(event.isLive ? HaloInk.bronze : HaloInk.creamMute)
        audienceBadge
      }
    }
  }

  private var avatar: some View {
    ZStack {
      Circle()
        .fill(MoodPalette.auraColor(event.person.mood, l: 0.72))
        .frame(width: 42, height: 42)
        .shadow(color: MoodPalette.auraRing(event.person.mood, alpha: 0.38), radius: 7)
      PortraitView(personId: event.person.id, size: 36)
        .background(HaloTheme.portraitBacking, in: Circle())
    }
    .frame(width: 46, height: 46)
  }

  private var audienceBadge: some View {
    Text(event.audience.title.lowercased())
      .haloEyebrow(event.audience == .cerchio ? HaloInk.bronze : HaloInk.creamMute, size: 7.4, tracking: 1.5)
      .padding(.horizontal, 7)
      .padding(.vertical, 4)
      .background(Capsule().fill(HaloInk.creamWhisper))
      .overlay(Capsule().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
  }

  @ViewBuilder
  private var content: some View {
    switch event.kind {
    case .message(let text):
      noteDrop(text, label: "nota")
    case .vibe(let text):
      noteDrop(text, label: "vibe", accent: true)
    case .photoPost(let caption):
      photoDrop(caption)
    case .textPost(let body):
      longNoteDrop(body)
    case .audioPost(let caption):
      audioDrop(caption)
    case .moodChange:
      EmptyView()
    }
  }

  private func noteDrop(_ text: String, label: String, accent: Bool = false) -> some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(label)
        .haloEyebrow(accent ? HaloInk.bronze : HaloInk.creamMute, size: 7.8, tracking: 1.7)
      Text(text)
        .font(HaloType.serif(19))
        .foregroundStyle(HaloInk.cream)
        .lineSpacing(3)
        .lineLimit(6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.leading, 12)
    .overlay(alignment: .leading) {
      RoundedRectangle(cornerRadius: 1)
        .fill(accent ? MoodPalette.auraColor(event.person.mood, l: 0.68) : HaloInk.creamLine)
        .frame(width: 2)
    }
  }

  private func photoDrop(_ caption: String) -> some View {
    ZStack(alignment: .bottomLeading) {
      LinearGradient(
        colors: [
          MoodPalette.auraColor(event.person.mood, l: 0.42),
          MoodPalette.auraColor(event.person.mood, l: 0.18),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
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
      VStack(alignment: .leading, spacing: 6) {
        Text("scatto")
          .haloEyebrow(Color.white.opacity(0.70), size: 7.8, tracking: 1.8)
        if !caption.isEmpty {
          Text(caption)
            .font(HaloType.serif(15))
            .foregroundStyle(Color.white.opacity(0.95))
            .lineLimit(2)
        }
      }
      .padding(14)
    }
    .frame(height: 158)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(HaloInk.creamLine, lineWidth: 0.5)
    )
  }

  private func longNoteDrop(_ body: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("nota lunga")
        .haloEyebrow(HaloInk.creamMute, size: 7.8, tracking: 1.7)
      Text(body)
        .font(HaloType.ui(14, weight: .regular))
        .foregroundStyle(HaloInk.cream)
        .lineSpacing(3)
        .lineLimit(6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(13)
    .background(
      RoundedRectangle(cornerRadius: 15, style: .continuous)
        .fill(HaloInk.nightSurface.opacity(0.34))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 15, style: .continuous)
        .strokeBorder(HaloInk.creamLine, lineWidth: 0.5)
    )
  }

  private func audioDrop(_ caption: String) -> some View {
    HStack(spacing: 12) {
      ZStack {
        Circle()
          .fill(MoodPalette.auraColor(event.person.mood, l: 0.70))
        Image(systemName: "play.fill")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(.white)
          .offset(x: 1)
      }
      .frame(width: 34, height: 34)

      VStack(alignment: .leading, spacing: 7) {
        Text("audio")
          .haloEyebrow(HaloInk.creamMute, size: 7.8, tracking: 1.7)
        HStack(spacing: 2) {
          ForEach(0..<30, id: \.self) { i in
            Capsule()
              .fill(Color.white.opacity(i < 13 ? 0.78 : 0.22))
              .frame(width: 2, height: CGFloat(5 + abs(sin(Double(i) * 1.3)) * 16))
          }
        }
        .frame(height: 24)
      }

      Spacer()
      Text(caption.contains("0:") ? caption : "0:14")
        .font(HaloType.mono(9, weight: .medium))
        .kerning(0.4)
        .foregroundStyle(HaloInk.creamMute)
    }
    .padding(13)
    .background(
      RoundedRectangle(cornerRadius: 15, style: .continuous)
        .fill(HaloInk.nightSurface.opacity(0.34))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 15, style: .continuous)
        .strokeBorder(HaloInk.creamLine, lineWidth: 0.5)
    )
  }

  private var actionRow: some View {
    HStack(spacing: 8) {
      actionChip("whisper", icon: "paperplane")
      actionChip("eco", icon: "wave.3.right")
      Spacer()
      if event.isLive {
        Text("live")
          .haloEyebrow(HaloInk.bronze, size: 7.8, tracking: 1.7)
      }
    }
  }

  private func actionChip(_ label: String, icon: String) -> some View {
    HStack(spacing: 5) {
      Image(systemName: icon)
        .font(.system(size: 9, weight: .medium))
      Text(label)
        .font(HaloType.mono(8.5, weight: .medium))
        .kerning(0.5)
        .textCase(.uppercase)
    }
    .foregroundStyle(HaloInk.creamLow)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Capsule().fill(HaloInk.creamWhisper))
    .overlay(Capsule().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
  }

  private var systemEvent: some View {
    HStack(spacing: 8) {
      Rectangle()
        .fill(HaloInk.creamLine)
        .frame(height: 0.5)
      Circle()
        .fill(MoodPalette.auraColor(event.person.mood, l: 0.75))
        .frame(width: 6, height: 6)
      Text("\(event.person.name.lowercased()) ha cambiato vibe")
        .haloEyebrow(HaloInk.creamMute, size: 8.5, tracking: 1.8)
      Rectangle()
        .fill(HaloInk.creamLine)
        .frame(height: 0.5)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 8)
  }

  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 22, style: .continuous)
      .fill(.ultraThinMaterial)
      .overlay(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .fill(
            LinearGradient(
              colors: [
                Color.white.opacity(0.035),
                Color.clear,
                Color.black.opacity(0.12),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
      )
  }

  private var cardBorder: some View {
    RoundedRectangle(cornerRadius: 22, style: .continuous)
      .strokeBorder(event.isLive ? HaloInk.bronzeSoft : HaloInk.creamHair, lineWidth: event.isLive ? 0.8 : 0.5)
  }

  private func timeLabel(_ date: Date) -> String {
    let age = Date.now.timeIntervalSince(date)
    if age < 30 * 60 { return "ora" }
    if age < 3600 { return "\(Int(age / 60))m" }
    if age < 24 * 3600 { return "\(Int(age / 3600))h" }
    return "\(Int(age / (24 * 3600)))g"
  }
}

private struct PulseDropDock: View {
  enum DropType {
    case note
    case photo
    case audio
    case vibe
  }

  let scope: PulseScope
  @Binding var text: String
  @Binding var isDraftOpen: Bool
  var onPublish: () -> Void
  var onQuickDrop: (DropType) -> Void

  private var canPublish: Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    VStack(spacing: 9) {
      if isDraftOpen {
        draftPanel
          .transition(.opacity.combined(with: .move(edge: .bottom)))
      }

      HStack(spacing: 8) {
        dockButton("nota", icon: "square.and.pencil", type: .note)
        dockButton("scatto", icon: "camera", type: .photo)
        dockButton("audio", icon: "mic.fill", type: .audio)
        dockButton("vibe", icon: "sparkle", type: .vibe)
      }
      .padding(10)
      .background(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(.ultraThinMaterial)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
      )
      .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
    }
  }

  private var draftPanel: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text("nuovo drop")
          .haloEyebrow(HaloInk.creamMute, size: 8, tracking: 1.8)
        Rectangle()
          .fill(HaloInk.creamLine)
          .frame(height: 0.5)
        Text(scope.title.lowercased())
          .haloEyebrow(scope == .cerchio ? HaloInk.bronze : HaloInk.creamMute, size: 8, tracking: 1.8)
      }

      TextField("una cosa vera, adesso", text: $text, axis: .vertical)
        .textFieldStyle(.plain)
        .font(HaloType.serif(18))
        .foregroundStyle(HaloInk.cream)
        .lineLimit(2...5)
        .padding(.vertical, 4)

      HStack(spacing: 8) {
        Button {
          withAnimation(.easeInOut(duration: 0.18)) {
            isDraftOpen = false
          }
        } label: {
          Text("chiudi")
            .font(HaloType.mono(9, weight: .medium))
            .kerning(0.7)
            .textCase(.uppercase)
        }
        .foregroundStyle(HaloInk.creamMute)
        .buttonStyle(.plain)

        Spacer()

        Button(action: onPublish) {
          Text("pubblica")
            .font(HaloType.mono(9, weight: .semibold))
            .kerning(0.8)
            .textCase(.uppercase)
            .foregroundStyle(canPublish ? Color.black : HaloInk.creamMute)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(canPublish ? HaloInk.cream : HaloInk.creamWhisper))
            .overlay(Capsule().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(!canPublish)
      }
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
    )
    .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
  }

  private func dockButton(_ label: String, icon: String, type: DropType) -> some View {
    Button {
      onQuickDrop(type)
    } label: {
      VStack(spacing: 5) {
        Image(systemName: icon)
          .font(.system(size: 14, weight: .semibold))
        Text(label)
          .font(HaloType.mono(8.5, weight: .medium))
          .kerning(0.6)
          .textCase(.uppercase)
          .lineLimit(1)
          .minimumScaleFactor(0.82)
      }
      .foregroundStyle(HaloInk.creamLow)
      .frame(maxWidth: .infinity)
      .frame(height: 46)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(HaloInk.creamWhisper)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(HaloInk.creamLine, lineWidth: 0.5)
      )
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  PulseFeedView()
    .preferredColorScheme(.dark)
}
