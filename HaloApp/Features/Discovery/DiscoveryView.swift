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
      VStack(spacing: SwarmHalo.s3) {
        topBar
        searchField
        ScrollView {
          LazyVStack(spacing: 8) {
            if !query.isEmpty {
              header("risultati")
              ForEach(results, id: \.id) { p in row(p) }
              if results.isEmpty && !isLoading {
                SwarmEmptyState(
                  title: "nessun segnale.",
                  message: "cerca handle, artisti o account pubblici.",
                  activation: .rest
                )
              }
            } else {
              header("da scoprire")
              ForEach(trending, id: \.id) { p in row(p) }
            }
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 30)
        }
      }
      .padding(.top, 14)
      if isLoading {
        SwarmLoadingState(label: "sync discovery")
          .padding(.horizontal, SwarmHalo.s4)
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
    SwarmOperationalRail(title: "HALO / DISCOVERY", context: "public asteroids", activation: .operational) {
      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(SwarmHalo.inkSecondary)
          .swarmIconFrame()
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 18)
  }

  private var searchField: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(HaloInk.creamMute)
      TextField("cerca artisti, brand, voci", text: $query)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .foregroundStyle(HaloInk.cream)
        .font(HaloType.ui(14, weight: .regular))
    }
    .padding(.horizontal, 14).padding(.vertical, 12)
    .swarmSurface(.control, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput, style: .continuous))
    .padding(.horizontal, 16)
  }

  private func header(_ text: String) -> some View {
    Text(text)
      .haloEyebrow(HaloInk.creamMute, size: 8.5, tracking: 2.0)
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
    .swarmSurface(.card, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: on ? .rest : .operational)
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
