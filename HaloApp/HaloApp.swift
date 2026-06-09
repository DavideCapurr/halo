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
        .task {
          StoreKitManager.shared.startTransactionListener()
        }
        .onOpenURL { url in
          if let link = DeepLink(url: url) {
            state.handle(link: link)
          }
        }
    }
  }
}
