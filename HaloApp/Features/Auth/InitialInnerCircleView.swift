import SwiftUI
import HaloShared

/// Selezione dei primi 1-5 Inner durante onboarding.
/// Ricerca per handle (`ProfilesService.search`) → tap per aggiungere.
/// Per ogni aggiunta, segue (default `.nebula`) e propone tier `.inner`
/// (la controparte conferma più avanti).
struct InitialInnerCircleView: View {
  var onDone: () -> Void = {}
  var onSkip: () -> Void = {}

  @State private var query: String = ""
  @State private var results: [Profile] = []
  @State private var picked: [Profile] = []
  @State private var isSearching: Bool = false
  @State private var isWorking: Bool = false

  private let maxInner = 5

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      VStack(spacing: 18) {
        eyebrow
        searchField
        pickedRow
        resultsList
        Spacer(minLength: 0)
        ctaRow
      }
      .padding(.horizontal, 22)
      .padding(.top, 26)
      .padding(.bottom, 26)
      if isWorking {
        ProgressView().tint(.white)
      }
    }
    .preferredColorScheme(.dark)
  }

  // MARK: - subviews

  private var eyebrow: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("INNER · I PRIMI 5")
        .font(.system(size: 11, weight: .semibold))
        .kerning(1.4)
        .foregroundStyle(HaloTheme.textCaption)
      Text("scegli chi è davvero vicino")
        .font(.system(size: 24, weight: .semibold))
        .kerning(-0.5)
        .foregroundStyle(.white)
      Text("massimo 5 · li puoi aggiornare in ogni momento")
        .font(.system(size: 12))
        .foregroundStyle(Color.white.opacity(0.55))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var searchField: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.white.opacity(0.55))
      TextField("cerca per handle", text: $query)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .foregroundStyle(.white)
        .onChange(of: query) { _, _ in
          Task { await search() }
        }
    }
    .padding(.horizontal, 14).padding(.vertical, 12)
    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(HaloTheme.hairline, lineWidth: 0.5))
  }

  @ViewBuilder
  private var pickedRow: some View {
    if !picked.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          ForEach(picked, id: \.id) { p in
            Button {
              picked.removeAll { $0.id == p.id }
            } label: {
              HStack(spacing: 6) {
                Circle()
                  .fill(MoodPalette.auraColor(.warm, l: 0.72))
                  .frame(width: 18, height: 18)
                  .overlay(
                    PortraitView(personId: p.handle, size: 16)
                      .clipShape(Circle())
                  )
                Text("@\(p.handle)")
                  .font(.system(size: 12, weight: .medium))
                  .foregroundStyle(.white)
                Image(systemName: "xmark")
                  .font(.system(size: 9, weight: .bold))
                  .foregroundStyle(.white.opacity(0.55))
              }
              .padding(.horizontal, 10).padding(.vertical, 6)
              .background(MoodPalette.auraRing(.warm, alpha: 0.20), in: Capsule())
              .overlay(Capsule().strokeBorder(MoodPalette.auraRing(.warm, alpha: 0.45), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  private var resultsList: some View {
    ScrollView {
      LazyVStack(spacing: 8) {
        if isSearching {
          ProgressView().tint(.white).padding(.top, 18)
        } else if results.isEmpty && !query.isEmpty {
          Text("nessun handle che inizia con \"\(query)\"")
            .font(.system(size: 12))
            .foregroundStyle(Color.white.opacity(0.45))
            .padding(.top, 18)
        } else {
          ForEach(results, id: \.id) { p in
            Button {
              toggle(p)
            } label: {
              HStack(spacing: 12) {
                Circle()
                  .fill(MoodPalette.auraColor(.chill, l: 0.55))
                  .frame(width: 36, height: 36)
                  .overlay(
                    PortraitView(personId: p.handle, size: 32).clipShape(Circle())
                  )
                VStack(alignment: .leading, spacing: 2) {
                  Text(p.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                  Text("@\(p.handle)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: isPicked(p) ? "checkmark.circle.fill" : "plus.circle")
                  .font(.system(size: 18, weight: .regular))
                  .foregroundStyle(isPicked(p)
                    ? MoodPalette.auraColor(.warm, l: 0.85)
                    : Color.white.opacity(0.40))
              }
              .padding(.horizontal, 12).padding(.vertical, 10)
              .background(.white.opacity(isPicked(p) ? 0.06 : 0.03), in: RoundedRectangle(cornerRadius: 12))
              .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(HaloTheme.hairlineSoft, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.vertical, 4)
    }
  }

  private var ctaRow: some View {
    HStack {
      Button(action: onSkip) {
        Text("Salta")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color.white.opacity(0.55))
      }
      .buttonStyle(.plain)
      Spacer()
      Button { Task { await confirm() } } label: {
        Text(picked.isEmpty ? "Continua" : "Aggiungi i miei \(picked.count) Inner")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 18).padding(.vertical, 12)
          .background(
            LinearGradient(
              colors: [MoodPalette.auraColor(.warm, l: 0.78), MoodPalette.auraColor(.warm, l: 0.55)],
              startPoint: .top, endPoint: .bottom
            ),
            in: Capsule()
          )
          .shadow(color: MoodPalette.auraRing(.warm, alpha: 0.4), radius: 10, y: 4)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - actions

  private func isPicked(_ p: Profile) -> Bool {
    picked.contains(where: { $0.id == p.id })
  }

  private func toggle(_ p: Profile) {
    if let i = picked.firstIndex(where: { $0.id == p.id }) {
      picked.remove(at: i)
    } else if picked.count < maxInner {
      picked.append(p)
    }
  }

  @MainActor
  private func search() async {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { results = []; return }
    isSearching = true; defer { isSearching = false }
    if let found = try? await ProfilesService.shared.search(handle: q) {
      results = found
    }
  }

  @MainActor
  private func confirm() async {
    isWorking = true; defer { isWorking = false }
    for p in picked {
      _ = try? await FollowsService.shared.follow(p.id)
      try? await FollowsService.shared.proposeTier(.inner, for: p.id)
    }
    onDone()
  }
}
