import SwiftUI
import UIKit
import HaloShared

/// Compose flow vibe-first: mood (obbligatorio) → nota (opzionale) → momento
/// (foto/testo/audio/salta) → tier (default Inner) → CTA "Manda".
/// Anti-cringe: parte sempre col tier più ristretto; il tier selector mostra
/// numeri reali e dà un warning soft quando si allarga.
struct VibeFirstComposeView: View {
  enum Step: Int { case mood = 0, nota = 1, momento = 2, tier = 3 }
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
      progressBar
        .padding(.horizontal, 22).padding(.top, 14).padding(.bottom, 8)

      ScrollView {
        VStack(spacing: 18) {
          switch step {
          case .mood:    moodStep
          case .nota:    notaStep
          case .momento: momentoStep
          case .tier:    tierStep
          }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
      }

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

  private var progressBar: some View {
    HStack(spacing: 6) {
      ForEach(0..<4) { idx in
        Capsule()
          .fill(idx <= step.rawValue
            ? MoodPalette.auraColor(mood, l: 0.78)
            : Color.white.opacity(0.10))
          .frame(height: 3)
      }
    }
    .animation(.easeInOut(duration: 0.25), value: step)
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
          .font(.system(size: 14, weight: on ? .semibold : .medium))
          .kerning(-0.1)
          .foregroundStyle(on ? .white : Color.white.opacity(0.75))
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
          .font(.system(size: 16))
          .kerning(-0.1)
          .foregroundStyle(.white)
          .lineLimit(3, reservesSpace: true)
          .onChange(of: note) { _, newValue in
            if newValue.count > 60 { note = String(newValue.prefix(60)) }
          }
        Text("\(note.count)/60")
          .font(.system(.caption2, design: .monospaced))
          .kerning(0.2)
          .foregroundStyle(Color.white.opacity(0.35))
      }
      .padding(.horizontal, 14).padding(.vertical, 12)
      .haloContentGlass(in: RoundedRectangle(cornerRadius: 14))

      Button { note = ""; advance() } label: {
        Text("salta")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color.white.opacity(0.55))
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - step 3: momento

  private var momentoStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      stepHeading(eyebrow: "STEP 3 · MOMENTO", title: "vuoi aggiungere un momento?")
      Text("se non aggiungi nulla, condividi solo la presenza")
        .font(.system(size: 13))
        .foregroundStyle(Color.white.opacity(0.55))

      momentoOptions
      if momento == .testo {
        TextField("scrivi qui qualcosa…", text: $note, axis: .vertical)
          .textFieldStyle(.plain)
          .font(.system(size: 15))
          .foregroundStyle(.white)
          .lineLimit(6, reservesSpace: true)
          .padding(.horizontal, 14).padding(.vertical, 12)
          .haloContentGlass(in: RoundedRectangle(cornerRadius: 14))
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
              .foregroundStyle(on ? Color.white : Color.white.opacity(0.55))
              .frame(width: 22)
            Text(label)
              .font(.system(size: 15, weight: on ? .semibold : .medium))
              .foregroundStyle(on ? .white : Color.white.opacity(0.78))
            Spacer()
          }
          .padding(.horizontal, 14).padding(.vertical, 14)
          .haloGlass(in: RoundedRectangle(cornerRadius: 14), tint: on ? MoodPalette.auraColor(mood, l: 0.55) : nil, interactive: true)
        }
        .buttonStyle(.plain)
      }
    }
  }

  // MARK: - step 4: tier — anti-cringe, mostra conteggi reali

  private var tierStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      stepHeading(eyebrow: "STEP 4 · CON CHI", title: "condividi con…")
      Text("Halo parte dal tuo cerchio più stretto. Allargare è una scelta.")
        .font(.system(size: 13))
        .foregroundStyle(Color.white.opacity(0.55))

      VStack(spacing: 8) {
        ForEach(FriendshipTier.allCases.reversed(), id: \.self) { t in
          tierRow(t)
        }
      }

      if let warning = wideningWarning {
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.circle")
            .foregroundStyle(MoodPalette.auraColor(.warm, l: 0.78))
          Text(warning)
            .font(.system(size: 12))
            .foregroundStyle(Color.white.opacity(0.70))
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .haloGlass(in: RoundedRectangle(cornerRadius: 12), tint: MoodPalette.auraColor(.warm, l: 0.55))
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .animation(.easeInOut(duration: 0.20), value: tier)
  }

  private func tierRow(_ t: FriendshipTier) -> some View {
    let on = t == tier
    let n = tierCounts[t] ?? 0
    return Button {
      tier = t
      UISelectionFeedbackGenerator().selectionChanged()
    } label: {
      HStack(spacing: 12) {
        Circle()
          .fill(on ? MoodPalette.auraColor(mood, l: 0.85) : Color.white.opacity(0.30))
          .frame(width: 9, height: 9)
          .shadow(color: on ? MoodPalette.auraRing(mood, alpha: 0.55) : .clear, radius: 4)
        VStack(alignment: .leading, spacing: 2) {
          Text(t.label)
            .font(.system(size: 15, weight: on ? .semibold : .medium))
            .foregroundStyle(on ? .white : Color.white.opacity(0.85))
          Text(audienceLabel(for: t, count: n))
            .font(.system(size: 11))
            .foregroundStyle(Color.white.opacity(0.55))
        }
        Spacer()
        Text("\(n)")
          .font(HaloTheme.mono)
          .kerning(0.3)
          .foregroundStyle(Color.white.opacity(on ? 0.85 : 0.45))
      }
      .padding(.horizontal, 14).padding(.vertical, 12)
      .haloGlass(in: RoundedRectangle(cornerRadius: 14), tint: on ? MoodPalette.auraColor(mood, l: 0.55) : nil, interactive: true)
    }
    .buttonStyle(.plain)
  }

  private func audienceLabel(for t: FriendshipTier, count: Int) -> String {
    switch t {
    case .inner:  return "i tuoi \(count) Inner"
    case .close:  return "Inner + i tuoi \(count) Close"
    case .orbit:  return "Inner + Close + i tuoi \(count) Orbit"
    case .nebula: return "tutti quelli che ti seguono (\(count) in Nebula)"
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
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.55))
        }
        .buttonStyle(.plain)
      }
      Spacer()
      Button {
        if step == .tier { send() } else { advance() }
      } label: {
        Text(step == .tier ? "Manda" : "Avanti")
          .font(.system(size: 16, weight: .semibold))
          .kerning(-0.2)
          .foregroundStyle(.white)
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
        .font(.system(size: 11, weight: .semibold))
        .kerning(1.4)
        .textCase(.uppercase)
        .foregroundStyle(HaloTheme.textCaption)
      Text(title)
        .font(.system(size: 26, weight: .semibold))
        .kerning(-0.6)
        .foregroundStyle(.white)
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

#Preview {
  VibeFirstComposeView(
    tierCounts: [.inner: 4, .close: 12, .orbit: 28, .nebula: 84]
  )
}
