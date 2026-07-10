import XCTest
@testable import HaloShared

final class DeepLinkTests: XCTestCase {
  private let ringId = UUID()
  private let userId = UUID()

  // MARK: - Custom scheme (unchanged contract)

  func testSchemeRingJoinParsesToken() {
    let url = URL(string: "halo://ring/join/bocconi-orientation-week")!
    XCTAssertEqual(DeepLink(url: url), .ringJoin(token: "bocconi-orientation-week"))
  }

  func testSchemeInvite() {
    let url = URL(string: "halo://invite/abc123")!
    XCTAssertEqual(DeepLink(url: url), .invite(token: "abc123"))
  }

  func testSchemeRingById() {
    let url = URL(string: "halo://ring/\(ringId.uuidString)")!
    XCTAssertEqual(DeepLink(url: url), .ring(id: ringId))
  }

  func testSchemeReport() {
    let url = URL(string: "halo://report/\(userId.uuidString)")!
    XCTAssertEqual(DeepLink(url: url), .report(userId: userId))
  }

  // MARK: - Universal links (https)

  func testWebRingJoinParsesToken() {
    let url = URL(string: "https://halo.app/ring/join/bocconi-orientation-week")!
    XCTAssertEqual(DeepLink(url: url), .ringJoin(token: "bocconi-orientation-week"))
  }

  func testWebShortJoinFormParsesToken() {
    let url = URL(string: "https://halo.app/join/bocconi-orientation-week")!
    XCTAssertEqual(DeepLink(url: url), .ringJoin(token: "bocconi-orientation-week"))
  }

  func testWebJoinQueryFormParsesToken() {
    // Forma usata dal QR e dagli anchor della landing (robusta su hosting statico).
    let url = URL(string: "https://halo.app/join/?ring=bocconi-orientation-week")!
    XCTAssertEqual(DeepLink(url: url), .ringJoin(token: "bocconi-orientation-week"))
  }

  func testWebRingJoinQueryTokenParam() {
    let url = URL(string: "https://halo.app/join/?token=abc123")!
    XCTAssertEqual(DeepLink(url: url), .ringJoin(token: "abc123"))
  }

  func testWebInvite() {
    let url = URL(string: "https://halo.app/invite/abc123")!
    XCTAssertEqual(DeepLink(url: url), .invite(token: "abc123"))
  }

  func testWebRingById() {
    let url = URL(string: "https://halo.app/ring/\(ringId.uuidString)")!
    XCTAssertEqual(DeepLink(url: url), .ring(id: ringId))
  }

  func testWebSpace() {
    let url = URL(string: "https://halo.app/space/\(userId.uuidString)")!
    XCTAssertEqual(DeepLink(url: url), .haloSpace(userId: userId))
  }

  func testWebMemory() {
    let url = URL(string: "https://halo.app/memory")!
    XCTAssertEqual(DeepLink(url: url), .memory)
  }

  // MARK: - Rejections

  func testUnknownSchemeReturnsNil() {
    XCTAssertNil(DeepLink(url: URL(string: "ftp://halo.app/join/x")!))
  }

  func testWebUnknownRouteReturnsNil() {
    XCTAssertNil(DeepLink(url: URL(string: "https://halo.app/")!))
    XCTAssertNil(DeepLink(url: URL(string: "https://halo.app/unknown/x")!))
  }

  func testWebEmptyJoinTokenReturnsNil() {
    XCTAssertNil(DeepLink(url: URL(string: "https://halo.app/ring/join/")!))
  }
}
