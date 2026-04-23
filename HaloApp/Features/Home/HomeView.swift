import SwiftUI
import HaloShared

struct HomeView: View {
  @State private var vm = HomeViewModel()

  var body: some View {
    OrbitalFieldView(
      placements: vm.placements,
      vibesByUser: vm.vibes,
      handlesByUser: vm.handlesByUser
    )
    .task { await vm.load() }
  }
}
