import SwiftUI
import HaloShared

@main
struct HaloApp: App {
  @State private var state = AppState()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(state)
        .preferredColorScheme(.dark)
        // Nessun listener StoreKit all'avvio: `docs/PRODOTTO.md` §8 congela
        // paywall e acquisti fino a prova di ritenzione. `StoreKitManager`
        // resta in repo, spento.
        .onOpenURL { url in
          if let link = DeepLink(url: url) {
            state.handle(link: link)
          }
        }
    }
  }
}
