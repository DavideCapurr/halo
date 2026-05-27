import SwiftUI
import UIKit
import HaloShared

/// Compose flow vibe-first: mood (obbligatorio) → nota (opzionale) → Moment
/// (foto/testo/audio/salta) → tier (default Inner) → CTA "Manda".
/// Anti-cringe: parte sempre col tier più ristretto; il tier selector mostra
/// numeri reali e dà un warning soft quando si allarga.
struct VibeFirstComposeView: View {
  enum Step: Int, CaseIterable { case mood = 0, nota = 1, momento = 2, tier = 3 }
  enum Momento { case foto, testo, audio, salta }

  /// Conteggi delle proprie cerchie (per il tier selector). Vengono passati dall'esterno.
  let tierCounts: [FriendshipTier: Int]

  var onSend: (ComposeResult) -> Void = { _ in }
  var onClose: () -> Void = {}

  /// Output di ritorno della compose.
  struct ComposeResult {
    var mood: Mood
    var note: String
    var momento: Momento
    var tier: FriendshipTier
  }

  @State private var step: Step = .mood
  @State private var mood: Mood = .chill
  @State private var note: String = ""
  @State private var momento: Momento = .salta
  @State private var tier: FriendshipTier = .inner

  init(tierCounts: [FriendshipTier: Int],
       initialMood: Mood = .chill,
       onSend: @escaping (ComposeResult) -> Void = { _ in },
       onClose: @escaping () -> Void = {}) {
    self.tierCounts = tierCounts
    self.onSend = onSend
    self.onClose = onClose
    self._mood = State(initialValue: initialMood)
  }

  var body: some View {
    VStack(spacing: 0) {
      composeTopRail
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)

      HStack(alignment: .top, spacing: 12) {
        stepRail
          .padding(.leading, 18)
          .padding(.top, 6)

        ScrollView {
          stageCard
            .padding(.trailing, 18)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
      }
      .frame(maxHeight: .infinity)

      footer
        .padding(.horizontal, 22).padding(.bottom, 22).padding(.top, 8)
    }
    .background(haloSheetBackground())
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
  }

  // MARK: - progress

  private var composeTopRail: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text("COMPOSE / VIBE")
          .haloEyebrow(SwarmHalo.inkSecondary, size: 8.5, tracking: 2.3)
        Text(step.shortTitle)
          .font(HaloType.ui(13, weight: .semibold))
          .foregroundStyle(HaloInk.cream)
      }

      Rectangle()
        .fill(HaloInk.creamLine)
        .frame(height: 0.5)

      Text("\(step.rawValue + 1)/4")
        .font(HaloType.mono(10, weight: .semibold))
        .kerning(1.2)
        .foregroundStyle(HaloInk.creamLow)

      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(HaloInk.creamLow)
          .frame(width: 30, height: 30)
          .background(Circle().fill(SwarmHalo.inkWhisper))
          .overlay(Circle().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
      }
      .buttonStyle(.plain)
    }
  }

  private var stepRail: some View {
    VStack(spacing: 8) {
      ForEach(Step.allCases, id: \.self) { item in
        VStack(spacing: 6) {
          Circle()
            .fill(item.rawValue <= step.rawValue ? MoodPalette.auraColor(mood, l: 0.78) : SwarmHalo.strokeRest)
            .frame(width: item == step ? 11 : 7, height: item == step ? 11 : 7)
            .shadow(color: item == step ? MoodPalette.auraRing(mood, alpha: 0.35) : .clear, radius: 6)

          if item != .tier {
            Rectangle()
              .fill(item.rawValue < step.rawValue ? MoodPalette.auraColor(mood, l: 0.52) : HaloInk.creamLine)
              .frame(width: 0.5, height: 34)
          }
        }
        .frame(width: 22)
        .contentShape(Rectangle())
        .onTapGesture {
          guard item.rawValue <= step.rawValue else { return }
          UISelectionFeedbackGenerator().selectionChanged()
          step = item
        }
      }
    }
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous)
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.5)
    )
  }

  private var stageCard: some View {
    VStack(spacing: 18) {
      switch step {
      case .mood:    moodStep
      case .nota:    notaStep
      case .momento: momentoStep
      case .tier:    tierStep
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous)
        .strokeBorder(HaloInk.creamHair, lineWidth: 0.6)
    )
  }

  private var progressBar: some View {
    HStack(spacing: 6) {
      ForEach(0..<4) { idx in
        Capsule()
          .fill(idx <= step.rawValue
            ? MoodPalette.auraColor(mood, l: 0.78)
            : SwarmHalo.strokeRest)
          .frame(height: 3)
      }
    }
    .animation(SwarmHalo.easeSwarm(0.25), value: step)
  }

  // MARK: - step 1: mood

  private var moodStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      stepHeading(eyebrow: "STEP 1 · MOOD", title: "che colore hai oggi?")
      // Preview hero
      heroPreview
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(Mood.allCases, id: \.self) { m in
            moodChip(m)
          }
        }
        .padding(.horizontal, 2)
      }
    }
  }

  private var heroPreview: some View {
    ZStack {
      TimelineView(.animation(minimumInterval: 1.0 / 24)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / 3.2) * .pi * 2)
        Circle()
          .fill(
            RadialGradient(
              colors: [MoodPalette.auraRing(mood, alpha: 0.6), .clear],
              center: .center, startRadius: 0, endRadius: 110
            )
          )
          .frame(width: 220, height: 220)
          .blur(radius: 4)
          .scaleEffect(1.0 + 0.05 * phase)
      }
      Circle()
        .fill(MoodPalette.auraColor(mood, l: 0.78))
        .frame(width: 130, height: 130)
        .shadow(color: MoodPalette.auraRing(mood, alpha: 0.5), radius: 25)
      PortraitView(personId: "self|hero", size: 122)
        .background(HaloTheme.portraitBacking, in: Circle())
    }
    .frame(width: 220, height: 220)
    .frame(maxWidth: .infinity)
  }

  private func moodChip(_ m: Mood) -> some View {
    let on = m == mood
    return Button {
      mood = m
      UISelectionFeedbackGenerator().selectionChanged()
    } label: {
      HStack(spacing: 6) {
        Circle()
          .fill(MoodPalette.auraColor(m, l: 0.8))
          .frame(width: 7, height: 7)
          .shadow(color: MoodPalette.auraRing(m, alpha: 0.6), radius: 3)
        Text(m.rawValue)
          .font(HaloType.ui(14, weight: on ? .semibold : .medium))
          .foregroundStyle(on ? HaloInk.cream : HaloInk.creamLow)
      }
      .padding(.horizontal, 16).padding(.vertical, 9)
      .haloGlass(in: Capsule(), tint: on ? MoodPalette.auraColor(m, l: 0.55) : nil, interactive: true)
    }
    .buttonStyle(.plain)
  }

  // MARK: - step 2: nota

  private var notaStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      stepHeading(eyebrow: "STEP 2 · NOTA", title: "una riga, se ti va")
      VStack(alignment: .leading, spacing: 6) {
        TextField("una nota breve (opzionale)", text: $note, axis: .vertical)
          .textFieldStyle(.plain)
          .font(HaloType.serif(17, weight: .regular))
          .foregroundStyle(HaloInk.cream)
          .lineLimit(3, reservesSpace: true)
          .onChange(of: note) { _, newValue in
            if newValue.count > 60 { note = String(newValue.prefix(60)) }
          }
        Text("\(note.count)/60")
          .font(HaloType.mono(10, weight: .medium))
          .kerning(1.0)
          .foregroundStyle(HaloInk.creamMute)
      }
      .padding(.horizontal, 14).padding(.vertical, 12)
      .haloContentGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput))

      Button { note = ""; advance() } label: {
        Text("salta")
          .font(HaloType.ui(14, weight: .medium))
          .foregroundStyle(HaloInk.creamMute)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - step 3: Moment

  private var momentoStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      stepHeading(eyebrow: "STEP 3 · MOMENT", title: "vuoi aggiungere un Moment?")
      Text("se non aggiungi nulla, condividi solo la presenza.")
        .font(HaloType.ui(13, weight: .regular))
        .foregroundStyle(HaloInk.creamLow)

      momentoOptions
      if momento == .testo {
        TextField("scrivi qui qualcosa…", text: $note, axis: .vertical)
          .textFieldStyle(.plain)
          .font(HaloType.serif(17, weight: .regular))
          .foregroundStyle(HaloInk.cream)
          .lineLimit(6, reservesSpace: true)
          .padding(.horizontal, 14).padding(.vertical, 12)
          .haloContentGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput))
      }
    }
  }

  @ViewBuilder
  private var momentoOptions: some View {
    let items: [(Momento, String, String)] = [
      (.foto,  "Foto",  "photo"),
      (.testo, "Testo", "text.alignleft"),
      (.audio, "Audio", "mic.fill"),
      (.salta, "Salta", "forward.end")
    ]
    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
      ForEach(items, id: \.0) { (kind, label, icon) in
        let on = momento == kind
        Button {
          momento = kind
          UISelectionFeedbackGenerator().selectionChanged()
        } label: {
          HStack(spacing: 10) {
            Image(systemName: icon)
              .font(.system(size: 16, weight: .regular))
              .foregroundStyle(on ? SwarmHalo.ink : SwarmHalo.inkMuted)
              .frame(width: 22)
            Text(label)
              .font(HaloType.ui(15, weight: on ? .semibold : .medium))
              .foregroundStyle(on ? HaloInk.cream : HaloInk.creamLow)
            Spacer()
          }
          .padding(.horizontal, 14).padding(.vertical, 14)
          .haloGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput), tint: on ? MoodPalette.auraColor(mood, l: 0.55) : nil, interactive: true)
        }
        .buttonStyle(.plain)
      }
    }
  }

  // MARK: - step 4: tier — anti-cringe, mostra conteggi reali

  private var tierStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      stepHeading(eyebrow: "STEP 4 · CON CHI", title: "condividi con…")
      Text("Halo parte da Inner. Allargare è una scelta.")
        .font(HaloType.ui(13, weight: .regular))
        .foregroundStyle(HaloInk.creamLow)

      VStack(spacing: 8) {
        ForEach(FriendshipTier.allCases.reversed(), id: \.self) { t in
          tierRow(t)
        }
      }

      if let warning = wideningWarning {
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.circle")
            .foregroundStyle(SwarmHalo.launchAmber)
          Text(warning)
            .font(HaloType.ui(12, weight: .regular))
            .foregroundStyle(HaloInk.creamLow)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .haloGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput), tint: SwarmHalo.launchAmber.opacity(0.22))
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .animation(SwarmHalo.easeSwarm(0.20), value: tier)
  }

  private func tierRow(_ t: FriendshipTier) -> some View {
    let on = t == tier
    let n = tierCounts[t] ?? 0
    let state = t.swarmHaloState
    return Button {
      tier = t
      UISelectionFeedbackGenerator().selectionChanged()
    } label: {
      HStack(spacing: 12) {
        Circle()
          .fill(on ? state.accent : state.stroke)
          .frame(width: 9, height: 9)
          .shadow(color: on ? state.glow : .clear, radius: 4)
        VStack(alignment: .leading, spacing: 2) {
          Text(t.label)
            .font(HaloType.ui(15, weight: on ? .semibold : .medium))
            .foregroundStyle(on ? HaloInk.cream : HaloInk.creamLow)
          Text(audienceLabel(for: t, count: n))
            .font(HaloType.ui(11, weight: .regular))
            .foregroundStyle(HaloInk.creamMute)
        }
        Spacer()
        Text("\(n)")
          .font(HaloType.mono(13, weight: .medium))
          .kerning(1.0)
          .foregroundStyle(on ? HaloInk.cream : HaloInk.creamMute)
      }
      .padding(.horizontal, 14).padding(.vertical, 12)
      .haloGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput), tint: on ? state.accent.opacity(0.18) : nil, interactive: true)
    }
    .buttonStyle(.plain)
  }

  private func audienceLabel(for t: FriendshipTier, count: Int) -> String {
    switch t {
    case .inner:  return "i tuoi \(count) di Inner"
    case .close:  return "Inner + i tuoi \(count) di Close"
    case .orbit:  return "Inner + Close + i tuoi \(count) in Orbita"
    case .nebula: return "Inner + Close + Orbita + \(count) in Nebula"
    }
  }

  /// Warning soft quando si sale di tier (più persone vedranno).
  private var wideningWarning: String? {
    guard tier != .inner else { return nil }
    let inner = tierCounts[.inner] ?? 0
    let now = tierCounts[tier] ?? 0
    let extras = max(now - inner, 0)
    guard extras > 0 else { return nil }
    return "anche \(extras) persone in più lo vedranno"
  }

  // MARK: - footer (back / next / send)

  private var footer: some View {
    HStack {
      if step != .mood {
        Button { back() } label: {
          Text("indietro")
            .font(HaloType.ui(14, weight: .medium))
            .foregroundStyle(HaloInk.creamMute)
        }
        .buttonStyle(.plain)
      }
      Spacer()
      Button {
        if step == .tier { send() } else { advance() }
      } label: {
        Text(step == .tier ? "manda" : "avanti")
          .font(HaloType.ui(15, weight: .semibold))
          .foregroundStyle(HaloInk.cream)
          .padding(.horizontal, 22).padding(.vertical, 12)
          .background(
            LinearGradient(
              colors: [MoodPalette.auraColor(mood, l: 0.78), MoodPalette.auraColor(mood, l: 0.55)],
              startPoint: .top, endPoint: .bottom
            ),
            in: Capsule()
          )
          .shadow(color: MoodPalette.auraRing(mood, alpha: 0.4), radius: 10, y: 4)
          .haloGlass(in: Capsule(), tint: MoodPalette.auraColor(mood, l: 0.55), interactive: true)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - helpers

  private func stepHeading(eyebrow: String, title: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(eyebrow)
        .font(HaloType.eyebrow(11))
        .kerning(2.4)
        .textCase(.uppercase)
        .foregroundStyle(HaloInk.creamMute)
      Text(title)
        .font(HaloType.serif(28, weight: .regular))
        .foregroundStyle(HaloInk.cream)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func advance() {
    let next = min(step.rawValue + 1, Step.tier.rawValue)
    step = Step(rawValue: next) ?? step
  }

  private func back() {
    let prev = max(step.rawValue - 1, Step.mood.rawValue)
    step = Step(rawValue: prev) ?? step
  }

  private func send() {
    onSend(.init(mood: mood, note: note, momento: momento, tier: tier))
  }
}

private extension VibeFirstComposeView.Step {
  var shortTitle: String {
    switch self {
    case .mood: return "mood"
    case .nota: return "nota"
    case .momento: return "Moment"
    case .tier: return "con chi"
    }
  }
}

#Preview {
  VibeFirstComposeView(
    tierCounts: [.inner: 4, .close: 12, .orbit: 28, .nebula: 84]
  )
}
