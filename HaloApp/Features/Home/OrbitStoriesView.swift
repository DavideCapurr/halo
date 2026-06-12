import SwiftUI
import HaloShared

/// Fullscreen stories viewer opened from the Orbit live metric.
/// It mirrors the HTML handoff: one active mutual moment at a time, fast
/// progress, mood-tinted media, local reactions, and a pull-down close.
struct OrbitStoriesView: View {
  let items: [MomentItem]
  let fallbackPeople: [HaloPersonNode]
  var onClose: () -> Void

  private let storyDuration: Double = 5.2
  private let tickInterval: Double = 1.0 / 30.0

  @State private var index: Int = 0
  @State private var progress: Double = 0
  @State private var paused: Bool = false
  @State private var dragY: CGFloat = 0
  @State private var isPressing: Bool = false
  @State private var didLongPress: Bool = false
  @State private var pressTask: Task<Void, Never>?
  @State private var reactions: [String: Set<ReactionKind>] = [:]
  @State private var reactionError: String?

  private var stories: [OrbitStory] {
    let realStories = OrbitStory.from(items: items)
    if !realStories.isEmpty { return realStories }
    return OrbitStory.from(people: fallbackPeople)
  }

  private var currentStory: OrbitStory? {
    guard stories.indices.contains(index) else { return stories.first }
    return stories[index]
  }

  var body: some View {
    ZStack {
      if stories.isEmpty {
        emptyState
      } else if let story = currentStory {
        GeometryReader { proxy in
          storyStage(story, width: proxy.size.width)
        }
      }
    }
    .preferredColorScheme(.dark)
    .ignoresSafeArea()
    .background(SwarmHalo.absoluteBlack)
    .task(id: progressKey) {
      await runProgressLoop()
    }
    .onChange(of: index) { _, _ in
      progress = 0
      paused = false
      dragY = 0
      cancelPress()
    }
    .onDisappear {
      cancelPress()
    }
  }

  private var progressKey: String {
    "\(index)-\(paused)-\(stories.count)"
  }

  private func runProgressLoop() async {
    guard !paused, !stories.isEmpty else { return }

    while !Task.isCancelled {
      try? await Task.sleep(nanoseconds: UInt64(tickInterval * 1_000_000_000))
      if Task.isCancelled || paused { return }

      let nextProgress = min(1, progress + tickInterval / storyDuration)
      progress = nextProgress

      if nextProgress >= 1 {
        advance()
        return
      }
    }
  }

  private var emptyState: some View {
    ZStack {
      SwarmHalo.absoluteBlack
      VStack(spacing: 12) {
        Text("silenzio.")
          .font(HaloType.serif(32, weight: .regular))
          .italic()
          .foregroundStyle(SwarmHalo.inkMuted)
        Text("nessuno vibra adesso.")
          .haloEyebrow(SwarmHalo.inkMuted, size: 10, tracking: 2.4)
        Button(action: onClose) {
          Text("chiudi")
            .font(HaloType.ui(13, weight: .medium))
            .foregroundStyle(SwarmHalo.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .haloGlass(in: Capsule(), interactive: true)
        }
        .buttonStyle(.plain)
        .padding(.top, 14)
      }
      .padding(28)
    }
  }

  private func storyStage(_ story: OrbitStory, width: CGFloat) -> some View {
    let scale = max(0.86, 1 - dragY / 1200)
    let opacity = max(0.42, 1 - dragY / 520)
    let cornerRadius = min(28, dragY / 8)

    return ZStack {
      SwarmHalo.absoluteBlack.opacity(opacity)

      ZStack {
        media(for: story)

        VStack(spacing: 0) {
          LinearGradient(
            colors: [SwarmHalo.absoluteBlack.opacity(0.58), .clear],
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: 220)
          Spacer()
          LinearGradient(
            colors: [SwarmHalo.absoluteBlack.opacity(0.72), .clear],
            startPoint: .bottom,
            endPoint: .top
          )
          .frame(height: 270)
        }
        .allowsHitTesting(false)

        VStack(spacing: 0) {
          progressBars
            .padding(.horizontal, 12)
            .padding(.top, 62)
          storyHeader(story)
            .padding(.horizontal, 14)
            .padding(.top, 12)
          Spacer()
          if story.kind == .photo, let caption = story.caption, !caption.isEmpty {
            captionView(caption)
              .padding(.horizontal, 22)
              .padding(.bottom, 16)
          }
          bottomControls(for: story)
            .padding(.horizontal, 14)
            .padding(.bottom, 28)
        }

        if paused {
          Text("in pausa")
            .haloEyebrow(HaloInk.onMedia.opacity(0.78), size: 9, tracking: 2.4)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(SwarmHalo.absoluteBlack.opacity(0.42), in: Capsule())
            .haloGlass(in: Capsule())
            .padding(.top, 88)
            .frame(maxHeight: .infinity, alignment: .top)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      .scaleEffect(scale)
      .offset(y: dragY)
      .animation(dragY == 0 ? SwarmHalo.easeSwarm(0.24) : nil, value: dragY)
      .contentShape(Rectangle())
      .gesture(storyGesture(width: width))
    }
  }

  @ViewBuilder
  private func media(for story: OrbitStory) -> some View {
    switch story.kind {
    case .photo:
      StoryPhotoCanvas(story: story)
    case .text:
      StoryTextCard(story: story)
    case .audio:
      StoryAudioCard(story: story)
    case .vibe:
      StoryVibeCard(story: story)
    }
  }

  private var progressBars: some View {
    HStack(spacing: 4) {
      ForEach(stories.indices, id: \.self) { i in
        GeometryReader { proxy in
          Capsule()
            .fill(HaloInk.onMedia.opacity(0.22))
            .overlay(alignment: .leading) {
              Capsule()
                .fill(HaloInk.onMedia.opacity(0.94))
                .frame(width: proxy.size.width * progressValue(for: i))
            }
        }
        .frame(height: 2.5)
      }
    }
  }

  private func progressValue(for progressIndex: Int) -> Double {
    if progressIndex < index { return 1 }
    if progressIndex == index { return min(1, progress) }
    return 0
  }

  private func storyHeader(_ story: OrbitStory) -> some View {
    HStack(spacing: 10) {
      PortraitView(personId: story.personId, size: 34, grayscale: true)
        .background(
          Circle()
            .fill(MoodPalette.auraColor(story.mood, l: 0.48).opacity(0.18))
        )
        .overlay(
          Circle()
            .strokeBorder(MoodPalette.auraColor(story.mood, l: 0.75).opacity(0.58), lineWidth: 0.7)
        )
        .shadow(color: MoodPalette.auraRing(story.mood, alpha: 0.45), radius: 8)

      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(story.name)
            .font(HaloType.serif(16, weight: .regular))
            .italic()
            .foregroundStyle(HaloInk.onMedia)
            .lineLimit(1)
          Text(story.tier.label.lowercased())
            .haloEyebrow(HaloInk.onMedia.opacity(0.60), size: 8.5, tracking: 2.2)
            .lineLimit(1)
        }
        HStack(spacing: 6) {
          Circle()
            .fill(MoodPalette.auraColor(story.mood, l: 0.78))
            .frame(width: 5, height: 5)
            .shadow(color: MoodPalette.auraRing(story.mood, alpha: 0.7), radius: 3)
          Text(story.mood.rawValue)
            .font(HaloType.ui(9.5, weight: .medium))
            .foregroundStyle(HaloInk.onMedia.opacity(0.70))
          Circle()
            .fill(HaloInk.onMedia.opacity(0.40))
            .frame(width: 2, height: 2)
          Text(story.relativeAge)
            .font(HaloType.mono(9, weight: .medium))
            .kerning(1)
            .foregroundStyle(HaloInk.onMedia.opacity(0.60))
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(HaloType.system(11, weight: .semibold))
          .foregroundStyle(HaloInk.onMedia.opacity(0.92))
          .frame(width: 32, height: 32)
          .haloGlass(in: Circle(), interactive: true, stroke: HaloInk.onMedia.opacity(0.18))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Chiudi stories")
    }
  }

  private func captionView(_ caption: String) -> some View {
    Text(caption)
      .font(HaloType.serif(19, weight: .regular))
      .italic()
      .foregroundStyle(HaloInk.onMedia)
      .lineSpacing(3)
      .shadow(color: SwarmHalo.absoluteBlack.opacity(0.6), radius: 18, y: 1)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func bottomControls(for story: OrbitStory) -> some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: 12) {
        bottomControlsContent(for: story)
      }
    } else {
      bottomControlsContent(for: story)
    }
  }

  private func bottomControlsContent(for story: OrbitStory) -> some View {
    VStack(spacing: 12) {
      Button(action: {}) {
        Text("rispondi a \(story.name.lowercased())...")
          .font(HaloType.ui(13, weight: .regular))
          .foregroundStyle(HaloInk.onMedia.opacity(0.70))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .haloGlass(in: Capsule(), interactive: true, stroke: HaloInk.onMedia.opacity(0.22))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Rispondi a \(story.name)")

      if story.postId != nil {
        HStack(spacing: 4) {
          ForEach(ReactionKind.allCases, id: \.self) { kind in
            reactionButton(kind, story: story)
          }
        }
      }

      if let reactionError {
        Text(reactionError)
          .font(HaloType.ui(11, weight: .medium))
          .foregroundStyle(SwarmActivationRole.attention.color)
          .lineLimit(2)
      }
    }
  }

  private func reactionButton(_ kind: ReactionKind, story: OrbitStory) -> some View {
    let active = reactions[story.id, default: []].contains(kind)
    let tint = active ? SwarmActivationRole.attention.color : HaloInk.onMedia.opacity(0.32)

    return Button {
      toggle(kind, for: story)
    } label: {
      ReactionGlyph(
        kind: kind,
        size: 18,
        color: active ? SwarmActivationRole.attention.color : HaloInk.onMedia.opacity(0.85)
      )
      .frame(maxWidth: .infinity)
      .frame(height: 44)
      .haloGlass(
        in: Capsule(),
        tint: active ? SwarmActivationRole.attention.color.opacity(0.22) : nil,
        interactive: true,
        stroke: active ? SwarmActivationRole.attention.stroke : HaloInk.onMedia.opacity(0.18)
      )
      .scaleEffect(active ? 1.06 : 1)
      .animation(SwarmMotion.tap, value: active)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(kind.rawValue)
    .foregroundStyle(tint)
  }

  private func toggle(_ kind: ReactionKind, for story: OrbitStory) {
    guard let postId = story.postId else { return }
    var selected = reactions[story.id, default: []]
    let wasSelected = selected.contains(kind)
    if wasSelected {
      selected.remove(kind)
    } else {
      selected.insert(kind)
    }
    reactions[story.id] = selected
    reactionError = nil

    Task {
      do {
        if wasSelected {
          try await ReactionsService.shared.unreact(to: postId, kind: kind)
        } else {
          try await ReactionsService.shared.react(to: postId, with: kind)
        }
      } catch {
        await MainActor.run {
          var reverted = reactions[story.id, default: []]
          if wasSelected {
            reverted.insert(kind)
          } else {
            reverted.remove(kind)
          }
          reactions[story.id] = reverted
          reactionError = SupabaseErrorMessage.describe(error, fallback: "Reazione non inviata.")
        }
      }
    }
  }

  private func storyGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        if !isPressing {
          isPressing = true
          didLongPress = false
          startPressPause()
        }
        if value.translation.height > 20 {
          dragY = max(0, value.translation.height)
        }
      }
      .onEnded { value in
        cancelPress()
        defer {
          isPressing = false
          didLongPress = false
          dragY = 0
        }

        if value.translation.height > 80 {
          HapticEngine.tap(for: .orbit)
          onClose()
          return
        }

        if didLongPress {
          paused = false
          return
        }

        let dx = value.translation.width
        let dy = value.translation.height
        guard abs(dx) < 14, abs(dy) < 14 else { return }

        if value.location.x < width * 0.34 {
          previous()
        } else {
          advance()
        }
      }
  }

  private func startPressPause() {
    pressTask?.cancel()
    pressTask = Task {
      try? await Task.sleep(nanoseconds: 220_000_000)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        guard isPressing else { return }
        didLongPress = true
        paused = true
      }
    }
  }

  private func cancelPress() {
    pressTask?.cancel()
    pressTask = nil
  }

  private func advance() {
    if index + 1 < stories.count {
      HapticEngine.selection()
      index += 1
    } else {
      onClose()
    }
  }

  private func previous() {
    if index > 0 {
      HapticEngine.selection()
      index -= 1
    } else {
      progress = 0
    }
  }
}

private struct StoryPhotoCanvas: View {
  let story: OrbitStory

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      ZStack {
        StorageImageView(path: story.mediaPath) {
          photoPlaceholder(size: size)
        }
        .frame(width: size.width, height: size.height)
        .clipped()

        RadialGradient(
          colors: [.clear, SwarmHalo.absoluteBlack.opacity(0.62)],
          center: .center,
          startRadius: min(size.width, size.height) * 0.26,
          endRadius: max(size.width, size.height) * 0.74
        )
      }
    }
  }

  private func photoPlaceholder(size: CGSize) -> some View {
    ZStack {
      LinearGradient(
        colors: [
          MoodPalette.auraColor(story.mood, l: 0.58).opacity(0.62),
          SwarmHalo.absoluteBlack
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      ForEach(0..<3, id: \.self) { i in
        let spec = story.orbSpec(i)
        Circle()
          .fill(
            RadialGradient(
              colors: [
                MoodPalette.auraColor(story.mood, l: 0.70 - Double(i) * 0.06).opacity(0.42),
                .clear
              ],
              center: .center,
              startRadius: 0,
              endRadius: spec.radius
            )
          )
          .frame(width: spec.radius * 2, height: spec.radius * 2)
          .blur(radius: 14)
          .position(x: size.width * spec.x, y: size.height * spec.y)
      }
    }
  }
}

private struct StoryTextCard: View {
  let story: OrbitStory

  var body: some View {
    ZStack {
      RadialGradient(
        colors: [
          MoodPalette.auraColor(story.mood, l: 0.52).opacity(0.24),
          SwarmHalo.absoluteBlack
        ],
        center: UnitPoint(x: 0.5, y: 0.38),
        startRadius: 0,
        endRadius: 420
      )

      Text(story.bodyText.isEmpty ? "moment" : "\"\(story.bodyText)\"")
        .font(HaloType.serif(30, weight: .regular))
        .italic()
        .foregroundStyle(SwarmHalo.ink)
        .multilineTextAlignment(.center)
        .lineSpacing(6)
        .padding(.horizontal, 36)
    }
  }
}

private struct StoryAudioCard: View {
  let story: OrbitStory

  var body: some View {
    ZStack {
      RadialGradient(
        colors: [
          MoodPalette.auraColor(story.mood, l: 0.52).opacity(0.22),
          SwarmHalo.absoluteBlack
        ],
        center: .center,
        startRadius: 0,
        endRadius: 460
      )

      VStack(spacing: 28) {
        StorageAudioPlaybackButton(
          path: story.mediaPath,
          accentMood: story.mood,
          size: 78,
          iconSize: 24,
          foregroundColor: SwarmHalo.ink,
          fillOpacity: 0.22,
          showsBorder: true
        )
        .shadow(color: MoodPalette.auraRing(story.mood, alpha: 0.42), radius: 28)

        HStack(alignment: .center, spacing: 3) {
          ForEach(0..<44, id: \.self) { i in
            Capsule()
              .fill(i < 18 ? MoodPalette.auraColor(story.mood, l: 0.72) : SwarmHalo.inkHairline)
              .frame(width: 2.5, height: CGFloat(6 + story.waveHeight(at: i)))
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 36)

        Text(story.mediaPath == nil ? "vocale" : "audio")
          .font(HaloType.mono(11, weight: .medium))
          .kerning(1.6)
          .foregroundStyle(SwarmHalo.inkSecondary)
      }
    }
  }
}

private struct StoryVibeCard: View {
  let story: OrbitStory

  var body: some View {
    ZStack {
      RadialGradient(
        colors: [
          MoodPalette.auraColor(story.mood, l: 0.56).opacity(0.32),
          SwarmHalo.absoluteBlack
        ],
        center: UnitPoint(x: 0.5, y: 0.42),
        startRadius: 0,
        endRadius: 460
      )

      VStack(spacing: 18) {
        Circle()
          .fill(MoodPalette.auraColor(story.mood, l: 0.78))
          .frame(width: 14, height: 14)
          .shadow(color: MoodPalette.auraRing(story.mood, alpha: 0.8), radius: 22)

        Text(story.mood.rawValue)
          .font(HaloType.serif(56, weight: .regular))
          .italic()
          .foregroundStyle(SwarmHalo.ink)
          .minimumScaleFactor(0.76)

        if story.note.isEmpty {
          Text("solo presenza")
            .haloEyebrow(SwarmHalo.inkMuted, size: 10, tracking: 2.8)
        } else {
          Text("\"\(story.note)\"")
            .font(HaloType.serif(18, weight: .regular))
            .italic()
            .foregroundStyle(SwarmHalo.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
        }
      }
    }
  }
}

private enum OrbitStoryKind {
  case photo
  case text
  case audio
  case vibe
}

private struct OrbitStory: Identifiable, Hashable {
  let id: String
  let personId: String
  let name: String
  let handle: String
  let tier: FriendshipTier
  let mood: Mood
  let note: String
  let activityAt: Date
  let kind: OrbitStoryKind
  let seed: UInt32
  let postId: UUID?
  let mediaPath: String?
  let caption: String?
  let bodyText: String

  var relativeAge: String {
    let minutes = max(0, Int(Date.now.timeIntervalSince(activityAt) / 60))
    if minutes < 1 { return "adesso" }
    if minutes < 60 { return "\(minutes) min" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h" }
    return "\(hours / 24)g"
  }

  static func from(items: [MomentItem]) -> [OrbitStory] {
    items
      .filter {
        $0.isMutual
          && $0.viewerTier != .asteroid
          && ($0.vibe != nil || ($0.lastPost?.isAlive ?? false))
      }
      .compactMap { item in
        let mood = item.vibe?.mood ?? item.lastPost?.mood ?? .chill
        let note = item.vibe?.note ?? item.lastPost?.caption ?? ""
        let post = item.lastPost
        let kind = post.map { OrbitStoryKind(postKind: $0.kind) } ?? .vibe
        let seed = stableHash(item.profile.id.uuidString)
        return OrbitStory(
          id: item.id.uuidString,
          personId: item.profile.id.uuidString,
          name: item.profile.displayName,
          handle: item.profile.handle,
          tier: item.viewerTier ?? .nebula,
          mood: mood,
          note: note,
          activityAt: item.lastActivityAt,
          kind: kind,
          seed: seed,
          postId: post?.id,
          mediaPath: post?.mediaPath,
          caption: kind == .photo ? post?.caption : nil,
          bodyText: post?.caption ?? note
        )
      }
      .sortedForStories()
  }

  static func from(people: [HaloPersonNode]) -> [OrbitStory] {
    people
      .filter { $0.isMutual && $0.tier != .asteroid && $0.hasActiveVibe }
      .map { person in
        let seed = stableHash(person.id)
        let kind = person.lastPostKind.map { OrbitStoryKind(postKind: $0) } ?? .vibe
        return OrbitStory(
          id: person.id,
          personId: person.id,
          name: person.name,
          handle: person.handle,
          tier: person.tier,
          mood: person.mood,
          note: person.note,
          activityAt: person.lastPostAt ?? .now,
          kind: kind,
          seed: seed,
          postId: person.lastPostId,
          mediaPath: person.lastPostMediaPath,
          caption: kind == .photo ? person.lastPostCaption : nil,
          bodyText: person.lastPostCaption ?? person.note
        )
      }
      .sortedForStories()
  }

  func orbSpec(_ index: Int) -> (x: CGFloat, y: CGFloat, radius: CGFloat) {
    let shifted = seed >> UInt32(index * 4)
    let x = CGFloat(18 + Int(shifted % 66)) / 100
    let y = CGFloat(18 + Int((shifted >> 3) % 68)) / 100
    let radius = CGFloat(120 + Int((shifted >> 6) % 80))
    return (x, y, radius)
  }

  func waveHeight(at index: Int) -> Int {
    6 + Int(Self.stableHash("\(id):\(index)") % 38)
  }

  private static func stableHash(_ string: String) -> UInt32 {
    var hash: UInt32 = 17
    for scalar in string.unicodeScalars {
      hash = hash &* 31 &+ scalar.value
    }
    return hash
  }
}

private extension OrbitStoryKind {
  init(postKind: PostKind) {
    switch postKind {
    case .photo: self = .photo
    case .text: self = .text
    case .audio: self = .audio
    }
  }
}

private extension Array where Element == OrbitStory {
  func sortedForStories() -> [OrbitStory] {
    sorted { lhs, rhs in
      if lhs.tier.rank != rhs.tier.rank { return lhs.tier.rank > rhs.tier.rank }
      return lhs.activityAt > rhs.activityAt
    }
  }
}

#Preview {
  OrbitStoriesView(items: [], fallbackPeople: SeedPeople.all, onClose: {})
}
