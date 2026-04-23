import SwiftUI
import HaloShared

struct RootView: View {
  @Environment(AppState.self) private var state

  var body: some View {
    Group {
      if state.isAuthenticated {
        // TODO step 8: sostituire con HomeView() + NavigationStack basato su AppState.route.
        Text("Home placeholder").foregroundStyle(.white)
      } else {
        // TODO step 4: SignInView con Sign in with Apple + OTP.
        Text("Sign in placeholder").foregroundStyle(.white)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
  }
}
