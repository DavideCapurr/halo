import SwiftUI
import HaloShared

/// Discovery: ricerca + lista account pubblici.
/// Tap su un risultato = follow asimmetrico (default `.nebula`); finiscono nel
/// proprio AsteroidBelt sull'orbital field.
struct DiscoveryView: View {
  @State private var query: String = ""
  @State private var results: [Profile] = []
  @State private var trending: [Profile] = []
  @State private var isLoading: Bool = false
  @State private var followedIds: Set<UUID> = []
  var onClose: () -> Void = {}

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      VStack(spacing: 14) {
        topBar
        searchField
        ScrollView {
          LazyVStack(spacing: 8) {
            if !query.isEmpty {
              header("RISULTATI")
              ForEach(results, id: \.id) { p in row(p) }
            } else {
              header("DA SCOPRIRE")
              ForEach(trending, id: \.id) { p in row(p) }
            }
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 30)
        }
      }
      .padding(.top, 14)
      if isLoading {
        ProgressView().tint(.white)
      }
    }
    .preferredColorScheme(.dark)
    .task { await loadTrending() }
    .onChange(of: query) { _, _ in
      Task { await search() }
    }
  }

  // MARK: - subviews

  private var topBar: some View {
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
      Text("ESPLORA")
        .font(HaloType.eyebrow(11))
        .kerning(2.4)
        .foregroundStyle(HaloInk.creamMute)
      Spacer()
      Color.clear.frame(width: 32, height: 32)
    }
    .padding(.horizontal, 18)
  }

  private var searchField: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(HaloInk.creamMute)
      TextField("cerca artisti, brand, voci…", text: $query)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .foregroundStyle(HaloInk.cream)
        .font(HaloType.ui(14, weight: .regular))
    }
    .padding(.horizontal, 14).padding(.vertical, 12)
    .haloContentGlass(in: RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
  }

  private func header(_ text: String) -> some View {
    Text(text)
      .font(HaloType.eyebrow(10))
      .kerning(2.0)
      .foregroundStyle(HaloInk.creamMute)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 8)
      .padding(.bottom, 2)
  }

  private func row(_ p: Profile) -> some View {
    let on = followedIds.contains(p.id)
    return HStack(spacing: 12) {
      Circle()
        .fill(MoodPalette.auraColor(.electric, l: 0.55))
        .frame(width: 40, height: 40)
        .overlay(PortraitView(personId: p.handle, size: 36).clipShape(Circle()))
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 5) {
          Text(p.displayName)
            .font(HaloType.serif(16, weight: .regular))
            .foregroundStyle(HaloInk.cream)
          Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 10))
            .foregroundStyle(MoodPalette.auraColor(.electric, l: 0.85))
        }
        Text("@\(p.handle)")
          .font(HaloType.ui(11, weight: .regular))
          .foregroundStyle(HaloInk.creamMute)
      }
      Spacer()
      Button {
        Task { await toggleFollow(p) }
      } label: {
        Text(on ? "seguito" : "segui")
          .font(HaloType.ui(12, weight: .semibold))
          .foregroundStyle(on ? HaloInk.creamMute : HaloInk.cream)
          .padding(.horizontal, 12).padding(.vertical, 6)
          .haloGlass(in: Capsule(), tint: on ? nil : MoodPalette.auraColor(.electric, l: 0.55), interactive: true)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 12).padding(.vertical, 10)
    .haloContentGlass(in: RoundedRectangle(cornerRadius: 12))
  }

  // MARK: - actions

  @MainActor
  private func loadTrending() async {
    isLoading = true; defer { isLoading = false }
    if let list = try? await ProfilesService.shared.discoverPublic(limit: 30) {
      trending = list
    }
  }

  @MainActor
  private func search() async {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { results = []; return }
    if let list = try? await ProfilesService.shared.searchPublic(handle: q) {
      results = list
    }
  }

  @MainActor
  private func toggleFollow(_ p: Profile) async {
    if followedIds.contains(p.id) {
      try? await FollowsService.shared.unfollow(p.id)
      followedIds.remove(p.id)
    } else {
      _ = try? await FollowsService.shared.follow(p.id)
      followedIds.insert(p.id)
    }
  }
}
