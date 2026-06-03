import XCTest
@testable import HaloShared

final class PostLifespanTests: XCTestCase {
  func testEasyIsShorterThanStandard() {
    XCTAssertLessThan(PostLifespan.easy.duration, PostLifespan.standard.duration)
  }

  func testEasyDurationIsThreeHours() {
    XCTAssertEqual(PostLifespan.easy.duration, 3 * 3600, accuracy: 0.5)
  }

  func testStandardPostExpiresIn72h() {
    let created = Date(timeIntervalSinceReferenceDate: 0)
    let post = HaloPost(userId: UUID(), kind: .text, createdAt: created)
    XCTAssertEqual(post.expiresAt.timeIntervalSince(created), 72 * 3600, accuracy: 0.5)
    XCTAssertFalse(post.isEasy)
  }

  func testEasyPostExpiresIn3hAndIsFlaggedEasy() {
    let created = Date(timeIntervalSinceReferenceDate: 0)
    let post = HaloPost(userId: UUID(), kind: .text, createdAt: created, lifespan: .easy)
    XCTAssertEqual(post.expiresAt.timeIntervalSince(created), 3 * 3600, accuracy: 0.5)
    XCTAssertTrue(post.isEasy)
  }

  func testExplicitExpiresAtOverridesLifespan() {
    let created = Date(timeIntervalSinceReferenceDate: 0)
    let custom = created.addingTimeInterval(10 * 3600)
    let post = HaloPost(userId: UUID(), kind: .text, createdAt: created, expiresAt: custom, lifespan: .easy)
    XCTAssertEqual(post.expiresAt, custom)
  }
}
