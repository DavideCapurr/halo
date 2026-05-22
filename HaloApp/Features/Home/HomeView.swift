import SwiftUI
import HaloShared

/// Schermata principale con `TabView` di sistema: Orbita · Pulse · Tu.
/// Le sheet (peek / vibe / tier / compose) restano coordinate qui.
struct HomeView: View {
  private enum HomeTab: Hashable {
    case orbit
    case pulse
    case profile
  }

  @State private var me: DemoPerson = SeedPeople.me
  @State private var people: [DemoPerson] = SeedPeople.all + SeedPeople.asteroids
  @State private var peek: DemoPerson? = nil
  @State private var showVibeSetter: Bool = false
  @State private var pendingProposal: TierConfirmationSheet.Proposal? = nil
  @State private var fieldZoom: ZoomLevel = .full
  @State private var selectedTab: HomeTab = .orbit
  @State private var showCompose: Bool = false

  /// Conteggio dei tier delle proprie cerchie per il `VibeFirstComposeView`.
  private var tierCounts: [FriendshipTier: Int] {
    Dictionary(grouping: people.filter(\.isMutual), by: \.tier).mapValues(\.count)
  }

  private var asteroids: [DemoPerson] { people.filter { !$0.isMutual } }

  private var mutuals: [DemoPerson] {
    people.filter(\.isMutual)
  }

  private var activeMutuals: [DemoPerson] {
    mutuals.filter(\.hasActiveVibe)
  }

  /// Lista mutuali ordinata per tier-rank, usata come "peers" nelle pagine
  /// HaloSpace così che lo swipe orizzontale resti consistente con l'orbita.
  private var sortedMutuals: [DemoPerson] {
    people.filter(\.isMutual)
      .sorted { (a, b) in
        if a.tier.rank != b.tier.rank { return a.tier.rank > b.tier.rank }
        return a.name < b.name
      }
  }

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      TabView(selection: $selectedTab) {
        orbitTab
          .tag(HomeTab.orbit)
          .tabItem {
            Label("Orbita", systemImage: "circle.grid.cross")
          }

        PulseFeedView(onPersonTap: { peek = $0 })
          .tag(HomeTab.pulse)
          .tabItem {
            Label("Pulse", systemImage: "waveform.path.ecg")
          }

        ProfilePlaceholder(me: me, onVibeTap: { showVibeSetter = true })
          .tag(HomeTab.profile)
          .tabItem {
            Label("Tu", systemImage: "person.crop.circle")
          }
      }
      .tint(HaloInk.bronze)
      .toolbarBackground(.ultraThinMaterial, for: .tabBar)
      .toolbarBackground(.visible, for: .tabBar)
    }
    .preferredColorScheme(.dark)
    .sheet(item: $peek) { person in
      HaloSpaceView(
        person: person,
        peers: sortedMutuals.isEmpty ? [person] : sortedMutuals,
        onClose: { peek = nil }
      )
    }
    .sheet(isPresented: $showVibeSetter) {
      VibeSetterView(
        initialMood: me.mood,
        initialNote: me.note,
        onSave: { newMood, newNote in
          me.mood = newMood
          me.note = newNote
          showVibeSetter = false
        },
        onClose: { showVibeSetter = false }
      )
    }
    .sheet(isPresented: $showCompose) {
      VibeFirstComposeView(
        tierCounts: tierCounts,
        initialMood: me.mood,
        onSend: { result in
          // Demo: aggiorna la propria vibe; il post effettivo passerà da PostsService.post.
          me.mood = result.mood
          me.note = result.note
          showCompose = false
        },
        onClose: { showCompose = false }
      )
    }
    .sheet(item: $pendingProposal) { proposal in
      TierConfirmationSheet(
        proposal: proposal,
        onAccept: {
          if let idx = people.firstIndex(where: { $0.id == proposal.person.id }) {
            people[idx].tier = proposal.to
          }
          pendingProposal = nil
        },
        onDecline: { pendingProposal = nil }
      )
    }
  }

  private var orbitTab: some View {
    VStack(spacing: 0) {
      orbitHeader
        .padding(.horizontal, 22)
        .padding(.top, 12)

      orbitStats
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 8)

      fieldArea
        .frame(maxHeight: .infinity)
    }
    .padding(.top, 4)
  }

  private var orbitHeader: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text("orbite")
          .haloEyebrow(HaloInk.creamMute, size: 9.5, tracking: 2.6)
        Rectangle()
          .fill(HaloInk.creamLine)
          .frame(height: 0.5)
        Text(Self.dateString)
          .font(HaloType.mono(9, weight: .medium))
          .kerning(1.5)
          .textCase(.uppercase)
          .foregroundStyle(HaloInk.creamMute)
      }

      HStack(alignment: .bottom, spacing: 14) {
        VStack(alignment: .leading, spacing: 5) {
          Text("chi è sveglio.")
            .font(HaloType.serif(36, weight: .regular))
            .foregroundStyle(HaloInk.cream)
            .kerning(-0.5)
            .lineLimit(1)
            .minimumScaleFactor(0.72)

          Text("inner · close · orbita")
            .font(HaloType.serif(15))
            .foregroundStyle(HaloInk.creamLow)
        }

        Spacer(minLength: 10)

        VStack(alignment: .trailing, spacing: 8) {
          Button(action: { showVibeSetter = true }) {
            HStack(spacing: 7) {
              Circle()
                .fill(MoodPalette.auraColor(me.mood, l: 0.80))
                .frame(width: 8, height: 8)
                .shadow(color: MoodPalette.auraRing(me.mood, alpha: 0.50), radius: 5)
              Text(me.mood.rawValue)
                .font(HaloType.ui(12, weight: .medium))
                .foregroundStyle(HaloInk.cream)
                .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(HaloInk.creamHair, lineWidth: 0.6))
          }
          .buttonStyle(.plain)

          Button(action: {}) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 14, weight: .regular))
              .foregroundStyle(HaloInk.creamLow)
              .frame(width: 34, height: 34)
              .background(Circle().fill(.ultraThinMaterial))
              .overlay(Circle().strokeBorder(HaloInk.creamHair, lineWidth: 0.6))
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private var orbitStats: some View {
    HStack(alignment: .center, spacing: 0) {
      orbitStatCell("inner", value: String(format: "%02d", tierCounts[.inner] ?? 0), accent: fieldZoom == .innerOnly)
      orbitStatSeparator
      orbitStatCell("live", value: String(format: "%02d", activeMutuals.count), accent: !activeMutuals.isEmpty)
      orbitStatSeparator
      orbitStatCell("zoom", value: fieldZoom.shortLabel, accent: fieldZoom != .full)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
    )
  }

  private var orbitStatSeparator: some View {
    Rectangle()
      .fill(HaloInk.creamLine)
      .frame(width: 0.5, height: 28)
  }

  private func orbitStatCell(_ label: String, value: String, accent: Bool = false) -> some View {
    VStack(spacing: 4) {
      Text(value)
        .font(HaloType.mono(18, weight: .semibold))
        .foregroundStyle(accent ? HaloInk.bronze : HaloInk.cream)
      Text(label)
        .haloEyebrow(HaloInk.creamMute, size: 8, tracking: 2.4)
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - field area (orbital + asteroids)

  private var fieldArea: some View {
    VStack(spacing: 0) {
      OrbitalFieldView(
        people: people,
        me: me,
        pulsing: true,
        onBubbleTap: { peek = $0 },
        onSelfTap: { showVibeSetter = true },
        onSelfLongPress: { showCompose = true },
        onProposeTier: { person, toTier in
          guard let idx = people.firstIndex(where: { $0.id == person.id }) else { return }

          if requiresTierConfirmation(from: person.tier, to: toTier) {
            pendingProposal = .init(person: person, from: person.tier, to: toTier)
          } else {
            people[idx].tier = toTier
          }
        },
        onZoomChange: { fieldZoom = $0 }
      )
      .frame(maxHeight: .infinity)

      if fieldZoom == .asteroids && !asteroids.isEmpty {
        AsteroidBeltView(
          people: asteroids,
          onTap: { peek = $0 }
        )
        .padding(.bottom, 6)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
      }
    }
    .animation(.easeInOut(duration: 0.30), value: fieldZoom)
  }

  private func requiresTierConfirmation(from: FriendshipTier, to: FriendshipTier) -> Bool {
    from == .nebula && to != .nebula
  }

  private static var dateString: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "it_IT")
    formatter.setLocalizedDateFormatFromTemplate("EEE d")
    return formatter.string(from: .now).replacingOccurrences(of: ".", with: "")
  }
}

private extension ZoomLevel {
  var shortLabel: String {
    switch self {
    case .innerOnly: return "INN"
    case .innerClose: return "CLO"
    case .full: return "ORB"
    case .asteroids: return "OUT"
    }
  }
}

extension TierConfirmationSheet.Proposal: Identifiable {
  var id: String { "\(person.id)-\(from.rawValue)-\(to.rawValue)" }
}

// MARK: - Profile placeholder

/// Quick profile destination — keeps the tab usable while the full profile
/// flow (`ProfileView`) is still TODO. Reuses the v2 editorial vocabulary.
private struct ProfilePlaceholder: View {
  let me: DemoPerson
  var onVibeTap: () -> Void = {}

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text(me.name.lowercased())
          .font(HaloType.serif(40, weight: .regular))
          .foregroundStyle(HaloInk.cream)
          .padding(.top, 80)

        HStack(spacing: 8) {
          Circle()
            .fill(MoodPalette.auraColor(me.mood, l: 0.78))
            .frame(width: 7, height: 7)
            .shadow(color: MoodPalette.auraRing(me.mood, alpha: 0.55), radius: 3)
          Text(me.mood.rawValue)
            .haloEyebrow(HaloInk.creamLow, size: 9.5, tracking: 2.4)
          Text("·")
            .haloEyebrow(HaloInk.creamMute)
          Text("@\(me.handle)")
            .haloEyebrow(HaloInk.creamMute)
        }

        Rectangle().fill(HaloInk.creamLine).frame(height: 0.5)

        Button(action: onVibeTap) {
          HStack {
            Text("modifica la tua vibe")
              .font(HaloType.ui(14, weight: .medium))
              .foregroundStyle(HaloInk.cream)
            Spacer()
            Image(systemName: "arrow.up.right")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(HaloInk.creamLow)
          }
          .padding(.vertical, 14)
        }
        .buttonStyle(.plain)

        Rectangle().fill(HaloInk.creamLine).frame(height: 0.5)

        Text("più funzioni in arrivo.")
          .font(HaloType.serif(16))
          .foregroundStyle(HaloInk.creamMute)
          .padding(.top, 12)
      }
      .padding(.horizontal, 26)
      .padding(.bottom, 80)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

#Preview {
  HomeView()
}
