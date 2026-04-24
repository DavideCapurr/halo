import SwiftUI
import UIKit
import HaloShared

/// Vibe setter sheet: portrait grande con halo pulsante + chips mood + nota 60ch + CTA.
struct VibeSetterView: View {
  let initialMood: Mood
  let initialNote: String
  var onSave: (Mood, String) -> Void = { _, _ in }
  var onClose: () -> Void = {}

  @State private var mood: Mood
  @State private var note: String

  init(initialMood: Mood, initialNote: String, onSave: @escaping (Mood, String) -> Void = { _, _ in }, onClose: @escaping () -> Void = {}) {
    self.initialMood = initialMood
    self.initialNote = initialNote
    self.onSave = onSave
    self.onClose = onClose
    self._mood = State(initialValue: initialMood)
    self._note = State(initialValue: initialNote)
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 6) {
          Text("La tua vibe")
            .font(.system(size: 13, weight: .medium))
            .kerning(1.5)
            .textCase(.uppercase)
            .foregroundStyle(HaloTheme.textCaption)
          Text("Cosa stai sentendo?")
            .font(.system(size: 26, weight: .semibold))
            .kerning(-0.6)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22).padding(.top, 18)

        // preview
        ZStack {
          previewHalo
          Circle()
            .fill(MoodPalette.auraColor(mood, l: 0.78))
            .frame(width: 130, height: 130)
            .shadow(color: MoodPalette.auraRing(mood, alpha: 0.5), radius: 25)
          PortraitView(personId: "self|hero", size: 122)
            .background(HaloTheme.portraitBacking, in: Circle())
        }
        .frame(width: 200, height: 200)
        .padding(.top, 12)
        .overlay(alignment: .bottom) {
          Text(mood.rawValue.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .kerning(1.2)
            .foregroundStyle(.white.opacity(0.75))
            .offset(y: -4)
        }
        .padding(.bottom, 18)

        // mood chips (horizontal scroll)
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(Mood.allCases, id: \.self) { m in
              moodChip(m)
            }
          }
          .padding(.horizontal, 20)
        }
        .padding(.bottom, 18)

        // nota
        VStack(alignment: .leading, spacing: 6) {
          TextField("una nota breve (opzionale)", text: $note)
            .textFieldStyle(.plain)
            .font(.system(size: 15))
            .kerning(-0.1)
            .foregroundStyle(.white)
            .submitLabel(.done)
            .onChange(of: note) { _, newValue in
              if newValue.count > 60 { note = String(newValue.prefix(60)) }
            }
          Text("\(note.count)/60 · scade tra 24h")
            .font(.system(.caption2, design: .monospaced))
            .kerning(0.2)
            .foregroundStyle(Color.white.opacity(0.35))
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(HaloTheme.hairline, lineWidth: 0.5))
        .padding(.horizontal, 22).padding(.bottom, 14)

        // CTA
        Button {
          onSave(mood, note)
        } label: {
          Text("Pubblica vibe")
            .font(.system(size: 16, weight: .semibold))
            .kerning(-0.2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
              LinearGradient(
                colors: [MoodPalette.auraColor(mood, l: 0.78), MoodPalette.auraColor(mood, l: 0.55)],
                startPoint: .top, endPoint: .bottom
              ),
              in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(color: MoodPalette.auraRing(mood, alpha: 0.4), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 22).padding(.bottom, 30)
      }
      .padding(.top, 6)
    }
    .background(haloSheetBackground())
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
  }

  private var previewHalo: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 24)) { ctx in
      let t = ctx.date.timeIntervalSinceReferenceDate
      let phase = sin((t / 3.2) * .pi * 2)
      Circle()
        .fill(
          RadialGradient(
            colors: [MoodPalette.auraRing(mood, alpha: 0.5), .clear],
            center: .center, startRadius: 0, endRadius: 110
          )
        )
        .frame(width: 220, height: 220)
        .blur(radius: 4)
        .scaleEffect(1.0 + 0.05 * phase)
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
}
