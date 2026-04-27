import SwiftUI
import HaloShared

/// Profilo per-persona: header (portrait grande + display + handle + tier + vibe attiva) +
/// lista post non scaduti tramite `PostsService.posts(forUser:)`.
/// Swipe orizzontale per navigare tra persone dello stesso tier (passate come `peers`).
/// Stato empty con mood se non ha post attivi.
struct HaloSpaceView: View {
  let initialPerson: DemoPerson
  /// Persone dello stesso tier per il navigation swipe orizzontale.
  let peers: [DemoPerson]
  var onClose: () -> Void = {}

  @State private var index: Int

  init(person: DemoPerson, peers: [DemoPerson], onClose: @escaping () -> Void = {}) {
    self.initialPerson = person
    self.peers = peers.isEmpty ? [person] : peers
    self.onClose = onClose
    let i = (peers.isEmpty ? [person] : peers).firstIndex { $0.id == person.id } ?? 0
    self._index = State(initialValue: i)
  }

  private var current: DemoPerson { peers[index] }

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
        .animation(.easeInOut(duration: 0.25), value: index)
      }
    }
    .preferredColorScheme(.dark)
  }

  // MARK: - top row (close + paginator dots)

  private var topRow: some View {
    HStack {
      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white.opacity(0.85))
          .frame(width: 32, height: 32)
          .background(.white.opacity(0.06), in: Circle())
      }
      .buttonStyle(.plain)
      Spacer()
      if peers.count > 1 {
        HStack(spacing: 4) {
          ForEach(0..<peers.count, id: \.self) { i in
            Circle()
              .fill(i == index ? Color.white.opacity(0.85) : Color.white.opacity(0.20))
              .frame(width: 5, height: 5)
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
  let person: DemoPerson
  @State private var posts: [HaloPost] = []
  @State private var isLoading: Bool = true

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        if isLoading {
          ProgressView().tint(.white).padding(40).frame(maxWidth: .infinity)
        } else if posts.isEmpty {
          emptyState
        } else {
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
    HStack(spacing: 16) {
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
          .fill(MoodPalette.auraColor(person.mood, l: 0.72))
          .frame(width: 96, height: 96)
          .shadow(color: MoodPalette.auraRing(person.mood, alpha: 0.55), radius: 12)
        PortraitView(personId: person.id, size: 88)
          .background(HaloTheme.portraitBacking, in: Circle())
      }
      .frame(width: 130, height: 130)

      VStack(alignment: .leading, spacing: 6) {
        Text(person.name)
          .font(.system(size: 22, weight: .semibold))
          .kerning(-0.4)
          .foregroundStyle(.white)
        HStack(spacing: 8) {
          Text("@\(person.handle)")
            .font(.system(size: 13))
            .foregroundStyle(HaloTheme.textMuted)
          tierBadge
        }
        if person.hasActiveVibe {
          HStack(spacing: 6) {
            Circle()
              .fill(MoodPalette.auraColor(person.mood, l: 0.85))
              .frame(width: 7, height: 7)
              .shadow(color: MoodPalette.auraRing(person.mood, alpha: 0.55), radius: 3)
            Text(person.mood.rawValue)
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Color.white.opacity(0.85))
            if !person.note.isEmpty {
              Text("\u{201C}\(person.note)\u{201D}")
                .font(.system(size: 12)).italic()
                .foregroundStyle(Color.white.opacity(0.60))
                .lineLimit(1)
            }
          }
          .padding(.top, 2)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.top, 6).padding(.bottom, 4)
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

  // MARK: - empty state

  private var emptyState: some View {
    VStack(spacing: 14) {
      ZStack {
        Circle()
          .fill(
            RadialGradient(
              colors: [MoodPalette.auraRing(person.mood, alpha: 0.30), .clear],
              center: .center, startRadius: 0, endRadius: 70
            )
          )
          .frame(width: 130, height: 130)
        Circle()
          .strokeBorder(MoodPalette.auraColor(person.mood, l: 0.55).opacity(0.5), style: .init(lineWidth: 1, dash: [3, 4]))
          .frame(width: 64, height: 64)
      }
      Text("HaloSpace vuoto")
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(.white)
      Text("nessun momento attivo nelle ultime 72h")
        .font(.system(size: 13))
        .foregroundStyle(Color.white.opacity(0.55))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 32)
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

  private func demoPosts(for p: DemoPerson) -> [HaloPost] {
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
