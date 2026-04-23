import Foundation
import Observation
import HaloShared

@Observable
final class AppState {
  enum Route: Hashable {
    case home
    case haloSpace(userId: UUID)
    case profile(userId: UUID)
  }

  var currentProfile: Profile?
  var isAuthenticated: Bool { currentProfile != nil }
  var route: Route = .home

  func handle(link: DeepLink) {
    switch link {
    case .haloSpace(let userId):
      route = .haloSpace(userId: userId)
    }
  }
}
