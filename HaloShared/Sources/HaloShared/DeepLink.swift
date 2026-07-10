import Foundation

/// User-facing app routes. Existing HaloSpace links stay stable; invite,
/// memory and report routes give redesigned surfaces URL contracts before
/// all backend features land.
public enum DeepLink: Equatable {
  case haloSpace(userId: UUID)
  case invite(token: String)
  case memory
  case ring(id: UUID)
  case ringJoin(token: String)
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
    case .report(let id):
      return URL(string: "\(Self.scheme)://report/\(id.uuidString)")
    }
  }

  /// Accetta sia lo scheme custom `halo://…` sia gli universal link https della
  /// landing (`https://<dominio>/…`). Il QR dell'orientation week ora codifica
  /// un link https: se l'app è installata iOS la apre direttamente (Associated
  /// Domains), altrimenti la pagina web fa da fallback verso TestFlight.
  public init?(url: URL) {
    // Per lo scheme il "tipo" di route è l'host (`halo://ring/join/token`);
    // per gli universal link l'host è il dominio, quindi il tipo è il primo
    // path component (`https://halo.app/ring/join/token`). Normalizziamo i due
    // casi in `type` + `rest` così il resto del parsing è condiviso.
    let isWebLink = url.scheme == "https" || url.scheme == "http"
    guard url.scheme == Self.scheme || isWebLink else { return nil }

    let pathParts = url.pathComponents.filter { $0 != "/" }
    guard let type = isWebLink ? pathParts.first : url.host else { return nil }
    let rest: [String] = isWebLink ? Array(pathParts.dropFirst()) : pathParts

    // Il QR passa il token come query (`/join/?ring=<token>`), la forma più
    // robusta su hosting statico: quando iOS apre l'app via universal link
    // riceve l'URL completo, quindi qui recuperiamo il token anche dalla query.
    let queryToken: String? = isWebLink
      ? URLComponents(url: url, resolvingAgainstBaseURL: false)?
          .queryItems?.first(where: { $0.name == "ring" || $0.name == "token" })?.value
      : nil

    switch type {
    case "space":
      if let last = rest.last, let id = UUID(uuidString: last) {
        self = .haloSpace(userId: id)
        return
      }
    case "invite":
      if let token = rest.last, !token.isEmpty {
        self = .invite(token: token)
        return
      }
    case "memory":
      self = .memory
      return
    case "ring":
      if rest.first == "join", let token = rest.dropFirst().first, !token.isEmpty {
        self = .ringJoin(token: token)
        return
      }
      if let token = queryToken, !token.isEmpty {
        self = .ringJoin(token: token)
        return
      }
      if let last = rest.last, let id = UUID(uuidString: last) {
        self = .ring(id: id)
        return
      }
    case "join":
      // Universal link del QR: forma breve `/join/token` o query `/join/?ring=token`.
      if let token = rest.first, !token.isEmpty {
        self = .ringJoin(token: token)
        return
      }
      if let token = queryToken, !token.isEmpty {
        self = .ringJoin(token: token)
        return
      }
    case "report":
      if let last = rest.last, let id = UUID(uuidString: last) {
        self = .report(userId: id)
        return
      }
    default:
      return nil
    }
    return nil
  }
}
