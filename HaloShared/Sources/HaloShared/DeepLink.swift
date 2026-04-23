import Foundation

/// Schema: `halo://space/<userId>` per aprire l'Halo Space di un utente dal widget.
public enum DeepLink {
  case haloSpace(userId: UUID)

  public static let scheme = "halo"

  public var url: URL? {
    switch self {
    case .haloSpace(let id):
      return URL(string: "\(Self.scheme)://space/\(id.uuidString)")
    }
  }

  public init?(url: URL) {
    guard url.scheme == Self.scheme else { return nil }
    let components = url.pathComponents.filter { $0 != "/" }
    if url.host == "space", let last = components.last, let id = UUID(uuidString: last) {
      self = .haloSpace(userId: id)
      return
    }
    return nil
  }
}
