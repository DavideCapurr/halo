import SwiftUI
import HaloShared

/// Profile surface for the current user. It keeps Plus, Memory and safety
/// surfaces visible as real SWARM command objects even while backend work is
/// staged for later phases.
struct ProfileView: View {
  @Environment(AppState.self) private var state

  let person: HaloPersonNode
  var tierCounts: [FriendshipTier: Int] = [:]
  var onVibeTap: () -> Void = {}
  var onComposeTap: () -> Void = {}

  @State private var showPlus: Bool = false
  @State private var showDiscovery: Bool = false
  @State private var showBocconiVerify: Bool = false
  @State private var showEventRings: Bool = false
  @State private var showClubRings: Bool = false
  @State private var showMemory: Bool = false

  init(
    person: HaloPersonNode,
    tierCounts: [FriendshipTier: Int] = [:],
    onVibeTap: @escaping () -> Void = {},
    onComposeTap: @escaping () -> Void = {}
  ) {
    self.person = person
    self.tierCounts = tierCounts
    self.onVibeTap = onVibeTap
    self.onComposeTap = onComposeTap
  }

  init(userId: UUID) {
    self.person = HaloPersonNode(
      id: userId.uuidString,
      handle: "halo",
      name: "Halo",
      tier: .inner,
      mood: .chill,
      note: "presenza, non performance",
      hasNew: false
    )
  }

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: SwarmHalo.s4) {
          rail
          heroNode
          haloLedger
          commandPanel
          memoryPanel
          safetyPanel
        }
        .padding(.horizontal, SwarmHalo.s4)
        .padding(.top, SwarmHalo.s3)
        .padding(.bottom, 112)
      }
      .scrollIndicators(.hidden)
    }
    .sheet(isPresented: $showPlus) { PlusUpsellView() }
    .sheet(isPresented: $showDiscovery) { DiscoveryView { showDiscovery = false } }
    .sheet(isPresented: $showBocconiVerify) { BocconiVerifyView() }
    .sheet(isPresented: $showEventRings) { EventRingView() }
    .sheet(isPresented: $showClubRings) { ClubRingView() }
    .sheet(isPresented: $showMemory) {
      MemoryArchiveView(hasPlus: state.currentProfile?.hasPlus ?? false) {
        showMemory = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
          showPlus = true
        }
      }
    }
  }

  private var rail: some View {
    SwarmOperationalRail(title: "HALO / PROFILE", context: "@\(person.handle)") {
      SwarmCommandButton(label: "scopri", icon: "sparkle.magnifyingglass", activation: .operational) {
        showDiscovery = true
      }
    }
  }

  private var heroNode: some View {
    VStack(spacing: SwarmHalo.s4) {
      ZStack {
        Circle()
          .fill(
            RadialGradient(
              colors: [MoodPalette.auraRing(person.mood, alpha: 0.42), .clear],
              center: .center,
              startRadius: 0,
              endRadius: 120
            )
          )
          .frame(width: 220, height: 220)
        Circle()
          .strokeBorder(SwarmActivationRole.connected.stroke, lineWidth: SwarmStroke.node)
          .frame(width: 150, height: 150)
          .shadow(color: SwarmActivationRole.connected.glow, radius: 16)
        PortraitView(personId: person.id, size: 132, grayscale: true)
          .background(HaloTheme.portraitBacking, in: Circle())
      }
      .frame(maxWidth: .infinity)

      VStack(spacing: SwarmHalo.s2) {
        Text(person.name.lowercased())
          .font(HaloType.serif(48, weight: .regular))
          .foregroundStyle(SwarmHalo.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
        HStack(spacing: SwarmHalo.s2) {
          statusDot
          Text(person.mood.rawValue)
            .haloEyebrow(SwarmHalo.inkSecondary, size: 9, tracking: 2.1)
          Text("·")
            .foregroundStyle(SwarmHalo.inkMuted)
          Text("il tuo halo")
            .haloEyebrow(SwarmHalo.inkMuted, size: 9, tracking: 2.1)
        }
      }
    }
    .padding(.vertical, SwarmHalo.s4)
  }

  private var statusDot: some View {
    Circle()
      .fill(MoodPalette.auraColor(person.mood, l: 0.80))
      .frame(width: 7, height: 7)
      .shadow(color: MoodPalette.auraRing(person.mood, alpha: 0.55), radius: 4)
  }

  private var haloLedger: some View {
    HStack(spacing: 0) {
      metric("inner", count(.inner), .connected)
      divider
      metric("close", count(.close), .operational)
      divider
      metric("orbita", count(.orbit), .rest)
      divider
      metric("live", person.hasActiveVibe ? "01" : "00", .attention, active: person.hasActiveVibe)
    }
    .padding(.vertical, SwarmHalo.s3)
    .swarmSurface(.rail, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous))
  }

  private func metric(_ label: String, _ value: String, _ role: SwarmActivationRole, active: Bool = true) -> some View {
    SwarmMetricTile(label: label, value: value, activation: role, active: active)
      .frame(maxWidth: .infinity)
  }

  private func count(_ tier: FriendshipTier) -> String {
    String(format: "%02d", tierCounts[tier] ?? 0)
  }

  private var divider: some View {
    Rectangle()
      .fill(SwarmHalo.inkLine)
      .frame(width: SwarmStroke.hairline, height: 28)
  }

  private var commandPanel: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      sectionHeader("command")
      profileCommand("manda una vibe", "waveform.path.ecg", role: .connected, action: onVibeTap)
      profileCommand("aggiungi un Moment", "plus", role: .attention, action: onComposeTap)
      profileCommand("verifica Bocconi", "checkmark.seal", role: .connected) {
        showBocconiVerify = true
      }
      profileCommand("Event Ring", "qrcode.viewfinder", role: .attention) {
        showEventRings = true
      }
      profileCommand("Club e corsi", "person.3.sequence", role: .operational) {
        showClubRings = true
      }
      profileCommand("scopri account pubblici", "scope", role: .operational) {
        showDiscovery = true
      }
    }
    .padding(SwarmHalo.s4)
    .swarmPanel()
  }

  private var memoryPanel: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      sectionHeader("memory")
      Text("i frammenti del semestre restano privati finché non li riapri.")
        .font(HaloType.ui(13, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
      HStack {
        SwarmMetricTile(label: "frammenti", value: "00", activation: .rest, active: false)
        Spacer()
        SwarmCommandButton(label: "Memory", icon: "archivebox", activation: .attention) {
          showMemory = true
        }
        SwarmCommandButton(label: "Halo Plus", icon: "sparkles", activation: .attention) {
          showPlus = true
        }
      }
    }
    .padding(SwarmHalo.s4)
    .swarmPanel()
  }

  private var safetyPanel: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      sectionHeader("safety")
      Text("blocca, segnala e sposta distanza senza esporre il tier.")
        .font(HaloType.ui(13, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
      HStack(spacing: SwarmHalo.s2) {
        SwarmCommandButton(label: "report", icon: "exclamationmark.triangle", activation: .attention) {}
        SwarmCommandButton(label: "privacy", icon: "lock", activation: .rest) {}
      }
    }
    .padding(SwarmHalo.s4)
    .swarmPanel()
  }

  private func sectionHeader(_ text: String) -> some View {
    HStack(spacing: SwarmHalo.s2) {
      Text(text)
        .haloEyebrow(SwarmHalo.inkMuted, size: 8.5, tracking: 2.0)
      Rectangle()
        .fill(SwarmHalo.inkLine)
        .frame(height: SwarmStroke.hairline)
    }
  }

  private func profileCommand(
    _ title: String,
    _ icon: String,
    role: SwarmActivationRole,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: SwarmHalo.s3) {
        Image(systemName: icon)
          .font(HaloType.system(14, weight: .semibold))
          .foregroundStyle(role.color)
          .swarmIconFrame(active: true, activation: role)
        Text(title)
          .font(HaloType.ui(14, weight: .medium))
          .foregroundStyle(SwarmHalo.ink)
        Spacer()
        Image(systemName: "arrow.up.right")
          .font(HaloType.system(11, weight: .semibold))
          .foregroundStyle(SwarmHalo.inkMuted)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  ProfileView(
    person: SeedPeople.me,
    tierCounts: [.inner: 5, .close: 12, .orbit: 28, .nebula: 84]
  )
}
