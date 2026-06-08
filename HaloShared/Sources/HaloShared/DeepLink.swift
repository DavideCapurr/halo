import Foundation

/// User-facing app routes. Existing HaloSpace links stay stable; invite,
/// memory and report routes give redesigned surfaces URL contracts before
/// all backend features land.
public enum DeepLink {
  case haloSpace(userId: UUID)
  case invite(token: String)
  case memory
  case ring(id: UUID)
  case ringJoin(token: String)
  case campaign(id: UUID)
  case campaignContribute(slug: String)
  case report(userId: UUID)

  public static let scheme = "halo"

  public var url: URL? {
    switch self {
    case .haloSpace(let id):
      return URL(string: "\(Self.scheme)://space/\(id.uuidString)")
    case .invite(let token):
      return URL(string: "\(Self.scheme)://invite/\(token)")
    case .memory:
      return URL(string: "\(Self.scheme)://memory")
    case .ring(let id):
      return URL(string: "\(Self.scheme)://ring/\(id.uuidString)")
    case .ringJoin(let token):
      return URL(string: "\(Self.scheme)://ring/join/\(token)")
    case .campaign(let id):
      return URL(string: "\(Self.scheme)://campaign/\(id.uuidString)")
    case .campaignContribute(let slug):
      return URL(string: "\(Self.scheme)://campaign/c/\(slug)")
    case .report(let id):
      return URL(string: "\(Self.scheme)://report/\(id.uuidString)")
    }
  }

  public init?(url: URL) {
    guard url.scheme == Self.scheme else { return nil }
    let components = url.pathComponents.filter { $0 != "/" }
    if url.host == "space", let last = components.last, let id = UUID(uuidString: last) {
      self = .haloSpace(userId: id)
      return
    }
    if url.host == "invite", let token = components.last, !token.isEmpty {
      self = .invite(token: token)
      return
    }
    if url.host == "memory" {
      self = .memory
      return
    }
    if url.host == "ring" {
      if components.first == "join", let token = components.dropFirst().first, !token.isEmpty {
        self = .ringJoin(token: token)
        return
      }
      if let last = components.last, let id = UUID(uuidString: last) {
        self = .ring(id: id)
        return
      }
    }
    if url.host == "campaign" {
      if components.first == "c", let slug = components.dropFirst().first, !slug.isEmpty {
        self = .campaignContribute(slug: slug)
        return
      }
      if let last = components.last, let id = UUID(uuidString: last) {
        self = .campaign(id: id)
        return
      }
    }
    if url.host == "report", let last = components.last, let id = UUID(uuidString: last) {
      self = .report(userId: id)
      return
    }
    return nil
  }
}
