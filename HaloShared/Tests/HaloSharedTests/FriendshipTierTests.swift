import XCTest
@testable import HaloShared

final class FriendshipTierTests: XCTestCase {
  func testRankOrdering() {
    XCTAssertLessThan(FriendshipTier.nebula, FriendshipTier.orbit)
    XCTAssertLessThan(FriendshipTier.orbit,  FriendshipTier.close)
    XCTAssertLessThan(FriendshipTier.close,  FriendshipTier.inner)
  }

  func testRingRadiusDecreasesTowardsInner() {
    XCTAssertGreaterThan(FriendshipTier.nebula.ringRadius, FriendshipTier.inner.ringRadius)
  }

  func testBubbleSizeOrdering() {
    XCTAssertGreaterThan(FriendshipTier.inner.bubbleSize, FriendshipTier.close.bubbleSize)
    XCTAssertGreaterThan(FriendshipTier.close.bubbleSize, FriendshipTier.orbit.bubbleSize)
    XCTAssertGreaterThan(FriendshipTier.orbit.bubbleSize, FriendshipTier.nebula.bubbleSize)
  }

  func testSoftCaps() {
    XCTAssertEqual(FriendshipTier.inner.softCap, 5)
    XCTAssertEqual(FriendshipTier.close.softCap, 15)
    XCTAssertNil(FriendshipTier.nebula.softCap)
  }

  func testDeepLinkRoundtrip() {
    let id = UUID()
    let url = DeepLink.haloSpace(userId: id).url!
    guard case .haloSpace(let parsed) = DeepLink(url: url) else {
      return XCTFail("failed to parse deep link")
    }
    XCTAssertEqual(parsed, id)
  }

  func testInviteMemoryAndReportDeepLinks() {
    guard case .invite(let token) = DeepLink(url: DeepLink.invite(token: "abc123").url!) else {
      return XCTFail("failed to parse invite deep link")
    }
    XCTAssertEqual(token, "abc123")

    guard case .memory = DeepLink(url: DeepLink.memory.url!) else {
      return XCTFail("failed to parse memory deep link")
    }

    let id = UUID()
    guard case .report(let parsed) = DeepLink(url: DeepLink.report(userId: id).url!) else {
      return XCTFail("failed to parse report deep link")
    }
    XCTAssertEqual(parsed, id)
  }
}
