import SwiftUI
import UIKit
import HaloShared

/// Quick-compose "easy": frizione-zero. Un mood (obbligatorio), una riga
/// opzionale, e via. Niente step, niente Moment, niente tier selector — l'easy
/// va sempre ai tuoi Inner e sparisce in 3 ore, così non c'è la paura del
/// "resta lì per sempre".
struct EasyComposeView: View {
  var onSend: (Result) -> Void = { _ in }
  var onClose: () -> Void = {}

  /// Output della quick-compose. La durata è fissa (`PostLifespan.easy`).
  struct Result {
    var mood: Mood
    var note: String
  }

  @State private var mood: Mood
  @State private var note: String = ""

  init(initialMood: Mood = .chill,
       onSend: @escaping (Result) -> Void = { _ in },
       onClose: @escaping () -> Void = {}) {
    self.onSend = onSend
    self.onClose = onClose
    self._mood = State(initialValue: initialMood)
  }

  var body: some View {
    VStack(spacing: 0) {
      topRail
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)

      ScrollView {
        VStack(spacing: 18) {
          heroPreview
          moodPicker
          noteField
          lifespanHint
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
      }
      .scrollIndicators(.hidden)

      footer
        .padding(.horizontal, 22).padding(.bottom, 22).padding(.top, 8)
    }
    .background(haloSheetBackground())
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
  }

  // MARK: - top rail

  private var topRail: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text("EASY · SPARISCE TRA 3 ORE")
          .haloEyebrow(SwarmHalo.inkSecondary, size: 8.5, tracking: 2.3)
        Text("butta lì qualcosa")
          .font(HaloType.serif(22, weight: .regular))
          .foregroundStyle(HaloInk.cream)
      }
      Spacer()
      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(HaloType.system(12, weight: .semibold))
          .foregroundStyle(HaloInk.creamLow)
          .frame(width: 30, height: 30)
          .background(Circle().fill(SwarmHalo.inkWhisper))
          .overlay(Circle().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - hero

  private var heroPreview: some View {
    ZStack {
      TimelineView(.animation(minimumInterval: 1.0 / 24)) { ctx in
        let t = ctx.date.timeIntervalSinceReferenceDate
        let phase = sin((t / 3.2) * .pi * 2)
        Circle()
          .fill(
            RadialGradient(
              colors: [MoodPalette.auraRing(mood, alpha: 0.6), .clear],
              center: .center, startRadius: 0, endRadius: 90
            )
          )
          .frame(width: 180, height: 180)
          .blur(radius: 4)
          .scaleEffect(1.0 + 0.05 * phase)
      }
      Circle()
        .fill(MoodPalette.auraColor(mood, l: 0.78))
        .frame(width: 104, height: 104)
        .shadow(color: MoodPalette.auraRing(mood, alpha: 0.5), radius: 22)
      PortraitView(personId: "self|hero", size: 98)
        .background(HaloTheme.portraitBacking, in: Circle())
    }
    .frame(width: 180, height: 180)
    .frame(maxWidth: .infinity)
  }

  // MARK: - mood

  private var moodPicker: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(Mood.allCases, id: \.self) { m in
          moodChip(m)
        }
      }
      .padding(.horizontal, 2)
    }
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

  // MARK: - note

  private var noteField: some View {
    VStack(alignment: .leading, spacing: 6) {
      TextField("una riga, se ti va (opzionale)", text: $note, axis: .vertical)
        .textFieldStyle(.plain)
        .font(HaloType.serif(17, weight: .regular))
        .foregroundStyle(HaloInk.cream)
        .lineLimit(2, reservesSpace: true)
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
  }

  private var lifespanHint: some View {
    HStack(spacing: 8) {
      Image(systemName: "bolt.fill")
        .font(HaloType.system(11, weight: .semibold))
        .foregroundStyle(MoodPalette.auraColor(mood, l: 0.78))
      Text("va ai tuoi Inner e svanisce in 3 ore. nessuna pressione.")
        .font(HaloType.ui(12, weight: .regular))
        .foregroundStyle(HaloInk.creamLow)
      Spacer()
    }
    .padding(.horizontal, 12).padding(.vertical, 10)
    .haloGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput),
               tint: MoodPalette.auraColor(mood, l: 0.5).opacity(0.16))
  }

  // MARK: - footer

  private var footer: some View {
    HStack {
      Spacer()
      Button {
        onSend(.init(mood: mood, note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
      } label: {
        Text("manda")
          .font(HaloType.ui(15, weight: .semibold))
          .foregroundStyle(HaloInk.cream)
          .padding(.horizontal, 26).padding(.vertical, 12)
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
}

#Preview {
  EasyComposeView()
}
