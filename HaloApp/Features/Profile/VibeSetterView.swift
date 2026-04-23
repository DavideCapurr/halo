import SwiftUI
import HaloShared

/// Step 5: impostazione vibe corrente (mood + colore + nota opzionale).
struct VibeSetterView: View {
  @State private var mood: Mood = .chill
  @State private var note: String = ""

  var body: some View {
    VStack {
      Text("Imposta la tua vibe").font(.title2).foregroundStyle(.white)
      // TODO step 5: picker mood + color + nota, salva via VibesService.shared.setCurrent(...)
    }
  }
}
