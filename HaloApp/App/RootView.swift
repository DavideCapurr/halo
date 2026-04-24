import SwiftUI
import HaloShared

struct RootView: View {
  @Environment(AppState.self) private var state

  var body: some View {
    // TODO step 4: ripristinare il gate auth (SignInView se !isAuthenticated).
    // Mentre auth e Supabase services non sono ancora implementati, si entra
    // direttamente nella Home con seed locale per poter rivedere il design.
    HomeView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.black)
  }
}
