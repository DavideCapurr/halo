import SwiftUI
import HaloShared

/// Profilo per-persona: header (portrait grande + display + handle + tier + vibe attiva) +
/// lista post non scaduti tramite `PostsService.posts(forUser:)`.
/// Swipe orizzontale per navigare tra persone dello stesso tier (passate come `peers`).
/// Stato empty con mood se non ha post attivi.
struct HaloSpaceView: View {
  let initialPerson: HaloPersonNode
  /// Persone dello stesso tier per il navigation swipe orizzontale.
  let peers: [HaloPersonNode]
  var onClose: () -> Void = {}

  @State private var index: Int

  init(person: HaloPersonNode, peers: [HaloPersonNode], onClose: @escaping () -> Void = {}) {
    self.initialPerson = person
    self.peers = peers.isEmpty ? [person] : peers
    self.onClose = onClose
    let i = (peers.isEmpty ? [person] : peers).firstIndex { $0.id == person.id } ?? 0
    self._index = State(initialValue: i)
  }

  private var current: HaloPersonNode { peers[index] }

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      VStack(spacing: 0) {
        topRow
        TabView(selection: $index) {
          ForEach(Array(peers.enumerated()), id: \.element.id) { (i, p) in
            HaloSpacePage(person: p)
              .tag(i)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(SwarmHalo.easeSwarm(0.25), value: index)
      }
    }
    .preferredColorScheme(.dark)
  }

  // MARK: - top row (close + paginator dots)

  private var topRow: some View {
    HStack {
      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(HaloType.system(14, weight: .semibold))
          .foregroundStyle(SwarmHalo.inkSecondary)
          .frame(width: 32, height: 32)
          .background(SwarmHalo.inkWhisper, in: Circle())
      }
      .buttonStyle(.plain)
      Spacer()
      VStack(spacing: 5) {
        Text("HALO / SPACE")
          .haloEyebrow(current.tier.swarmHaloState.accent, size: 8, tracking: 2.2)
        if peers.count > 1 {
          HStack(spacing: 4) {
            ForEach(0..<peers.count, id: \.self) { i in
              Circle()
                .fill(i == index ? SwarmHalo.ink.opacity(0.85) : SwarmHalo.ink.opacity(0.20))
                .frame(width: 5, height: 5)
            }
          }
        }
      }
      Spacer()
      Color.clear.frame(width: 32, height: 32)
    }
    .padding(.horizontal, 18).padding(.vertical, 12)
  }
}

// MARK: - single page (header + post list)

private struct HaloSpacePage: View {
  let person: HaloPersonNode
  @State private var posts: [HaloPost] = []
  @State private var isLoading: Bool = true

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        spaceLedger
        if isLoading {
          ProgressView().tint(SwarmHalo.ink).padding(40).frame(maxWidth: .infinity)
        } else if posts.isEmpty {
          emptyState
        } else {
          streamHeader
          ForEach(posts, id: \.id) { post in
            PostCardView(
              post: post,
              viewerTier: person.tier,
              fallbackMood: person.mood
            )
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 40)
    }
    .task(id: person.id) {
      await load()
    }
  }

  // MARK: - header

  private var header: some View {
    VStack(spacing: 14) {
      ZStack {
        Circle()
          .fill(
            RadialGradient(
              colors: [MoodPalette.auraRing(person.mood, alpha: 0.55), .clear],
              center: .center, startRadius: 0, endRadius: 70
            )
          )
          .frame(width: 130, height: 130)
        Circle()
          .fill(person.tier.swarmHaloState.ringFill)
          .frame(width: 96, height: 96)
          .overlay(Circle().strokeBorder(person.tier.swarmHaloState.stroke, lineWidth: 1))
          .shadow(color: person.tier.swarmHaloState.glow, radius: 12)
        PortraitView(personId: person.id, size: 88, grayscale: true)
          .background(HaloTheme.portraitBacking, in: Circle())
      }
      .frame(width: 130, height: 130)

      VStack(spacing: 7) {
        Text(person.name.lowercased())
          .font(HaloType.serif(40, weight: .regular))
          .foregroundStyle(HaloInk.cream)
          .lineLimit(1)
          .minimumScaleFactor(0.70)
        HStack(spacing: 8) {
          Text("@\(person.handle)")
            .font(HaloType.ui(13, weight: .regular))
            .foregroundStyle(HaloInk.creamMute)
          tierBadge
        }
        if person.hasActiveVibe {
          HStack(spacing: 6) {
            Circle()
              .fill(MoodPalette.auraColor(person.mood, l: 0.85))
              .frame(width: 7, height: 7)
              .shadow(color: MoodPalette.auraRing(person.mood, alpha: 0.55), radius: 3)
            Text(person.mood.rawValue)
              .font(HaloType.ui(12, weight: .medium))
              .foregroundStyle(HaloInk.creamLow)
            if !person.note.isEmpty {
              Text("\u{201C}\(person.note)\u{201D}")
                .font(HaloType.serif(13, weight: .regular))
                .foregroundStyle(HaloInk.creamLow)
                .lineLimit(1)
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 7)
          .background(Capsule().fill(SwarmHalo.inkWhisper))
          .overlay(Capsule().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
        }
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 10)
    .padding(.bottom, 4)
  }

  private var tierBadge: some View {
    Text(person.tier.label)
      .font(HaloType.eyebrow(9))
      .kerning(1.8)
      .textCase(.uppercase)
      .foregroundStyle(person.tier.swarmHaloState.accent)
      .padding(.horizontal, 7)
      .padding(.vertical, 2.5)
      .haloGlass(in: Capsule(), tint: person.tier.swarmHaloState.accent.opacity(0.18))
  }

  private var spaceLedger: some View {
    HStack(spacing: 0) {
      ledgerCell("tier", person.tier.label)
      ledgerDivider
      ledgerCell("vibe", person.hasActiveVibe ? person.mood.rawValue : "rest")
      ledgerDivider
      ledgerCell("Moment", isLoading ? "--" : String(format: "%02d", posts.count))
    }
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous)
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
    )
  }

  private func ledgerCell(_ label: String, _ value: String) -> some View {
    VStack(spacing: 4) {
      Text(value)
        .font(HaloType.mono(13, weight: .semibold))
        .kerning(0.8)
        .foregroundStyle(label == "tier" ? person.tier.swarmHaloState.accent : HaloInk.cream)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
      Text(label)
        .haloEyebrow(HaloInk.creamMute, size: 7.4, tracking: 1.7)
    }
    .frame(maxWidth: .infinity)
  }

  private var ledgerDivider: some View {
    Rectangle()
      .fill(HaloInk.creamLine)
      .frame(width: 0.5, height: 26)
  }

  private var streamHeader: some View {
    HStack(spacing: 10) {
      Text("Moment")
        .haloEyebrow(HaloInk.creamMute, size: 8.5, tracking: 2.0)
      Rectangle().fill(HaloInk.creamLine).frame(height: 0.5)
      Text("72H")
        .font(HaloType.mono(8.5, weight: .medium))
        .kerning(1.2)
        .foregroundStyle(HaloInk.creamMute)
    }
    .padding(.top, 2)
  }

  // MARK: - empty state

  private var emptyState: some View {
    SwarmEmptyState(
      title: "halo silenzioso.",
      message: "nessun Moment attivo nelle ultime 72h.",
      activation: .rest
    )
  }

  // MARK: - load

  /// Demo: prova a caricare post reali; in caso di errore (no auth) genera dei placeholder
  /// derivati da `person` per popolare l'UI. Quando auth è attiva, sostituire con il fetch puro.
  @MainActor
  private func load() async {
    isLoading = true
    defer { isLoading = false }
    if let userUUID = UUID(uuidString: person.id),
       let real = try? await PostsService.shared.posts(forUser: userUUID), !real.isEmpty {
      posts = real
      return
    }
    posts = demoPosts(for: person)
  }

  private func demoPosts(for p: HaloPersonNode) -> [HaloPost] {
    guard let lastPostAt = p.lastPostAt else { return [] }
    let owner = UUID()
    var out: [HaloPost] = []
    out.append(HaloPost(
      userId: owner,
      kind: .photo,
      caption: p.note.isEmpty ? nil : p.note,
      mood: p.mood,
      minTier: .inner,
      createdAt: lastPostAt,
      expiresAt: lastPostAt.addingTimeInterval(72 * 3600)
    ))
    out.append(HaloPost(
      userId: owner,
      kind: .text,
      caption: "qualcosa di non detto",
      mood: p.mood,
      minTier: .close,
      createdAt: lastPostAt.addingTimeInterval(-6 * 3600),
      expiresAt: lastPostAt.addingTimeInterval(66 * 3600)
    ))
    return out
  }
}
