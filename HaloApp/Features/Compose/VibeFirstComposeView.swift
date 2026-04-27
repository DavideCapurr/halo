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
      .background(on ? MoodPalette.auraRing(m, alpha: 0.25) : Color.white.opacity(0.04), in: Capsule())
      .overlay(
        Capsule().strokeBorder(
          on ? MoodPalette.auraRing(m, alpha: 0.7) : HaloTheme.hairline,
          lineWidth: on ? 1 : 0.5
        )
      )
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
      .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
      .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(HaloTheme.hairline, lineWidth: 0.5))

      Button { note = ""; advance() } label: {
        Text("salta")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color.white.opacity(0.55))
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - step 3: momento (placeholder; completato nelle microtappe successive)

  private var momentoStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      stepHeading(eyebrow: "STEP 3 · MOMENTO", title: "vuoi aggiungere qualcosa?")
      Text("Foto / Testo / Audio / Salta")
        .foregroundStyle(.white.opacity(0.6))
    }
  }

  // MARK: - step 4: tier (placeholder; completato nelle microtappe successive)

  private var tierStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      stepHeading(eyebrow: "STEP 4 · CON CHI", title: "condividi con…")
      Text("Tier selector qui")
        .foregroundStyle(.white.opacity(0.6))
    }
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
