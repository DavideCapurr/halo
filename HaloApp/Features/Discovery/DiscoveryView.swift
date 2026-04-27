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
        .font(.system(size: 11, weight: .semibold))
        .kerning(1.4)
        .foregroundStyle(HaloTheme.textCaption)
      Spacer()
      Color.clear.frame(width: 32, height: 32)
    }
    .padding(.horizontal, 18)
  }

  private var searchField: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.white.opacity(0.55))
      TextField("cerca artisti, brand, voci…", text: $query)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .foregroundStyle(.white)
    }
    .padding(.horizontal, 14).padding(.vertical, 12)
    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(HaloTheme.hairline, lineWidth: 0.5))
    .padding(.horizontal, 16)
  }

  private func header(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 10, weight: .semibold))
      .kerning(1.2)
      .foregroundStyle(HaloTheme.textCaption)
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
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
          Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 10))
            .foregroundStyle(MoodPalette.auraColor(.electric, l: 0.85))
        }
        Text("@\(p.handle)")
          .font(.system(size: 11))
          .foregroundStyle(Color.white.opacity(0.55))
      }
      Spacer()
      Button {
        Task { await toggleFollow(p) }
      } label: {
        Text(on ? "Seguito" : "Segui")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(on ? Color.white.opacity(0.55) : .white)
          .padding(.horizontal, 12).padding(.vertical, 6)
          .background(
            on ? Color.white.opacity(0.06) : MoodPalette.auraRing(.electric, alpha: 0.30),
            in: Capsule()
          )
          .overlay(Capsule().strokeBorder(
            on ? HaloTheme.hairline : MoodPalette.auraRing(.electric, alpha: 0.55),
            lineWidth: 0.5
          ))
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 12).padding(.vertical, 10)
    .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(HaloTheme.hairlineSoft, lineWidth: 0.5))
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
