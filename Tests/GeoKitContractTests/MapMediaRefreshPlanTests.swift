import XCTest
@testable import GeoKitContract

final class MapMediaRefreshPlanTests: XCTestCase {
    func test_noopWhenLayoutNotReady() {
        let plan = MapMediaRefreshPlanner.plan(
            centerIndex: 0,
            cardCount: 6,
            peekRadius: 5,
            layoutReady: false,
            centerHasSnapshot: false,
            fanHasSnapshot: { _ in false }
        )
        XCTAssertTrue(plan.isNoop)
    }

    func test_noopWhenCenterOutOfRange() {
        let plan = MapMediaRefreshPlanner.plan(
            centerIndex: 9,
            cardCount: 6,
            peekRadius: 5,
            layoutReady: true,
            centerHasSnapshot: false,
            fanHasSnapshot: { _ in false }
        )
        XCTAssertTrue(plan.isNoop)
    }

    func test_capturesCenterWhenMissing() {
        let plan = MapMediaRefreshPlanner.plan(
            centerIndex: 0,
            cardCount: 6,
            peekRadius: 5,
            layoutReady: true,
            centerHasSnapshot: false,
            fanHasSnapshot: { _ in false }
        )
        XCTAssertFalse(plan.isNoop)
        XCTAssertTrue(plan.capturesCenterBeforeLive)
        XCTAssertEqual(plan.liveCardIndex, 0)
    }

    func test_skipsCenterCaptureWhenCached() {
        let plan = MapMediaRefreshPlanner.plan(
            centerIndex: 0,
            cardCount: 6,
            peekRadius: 5,
            layoutReady: true,
            centerHasSnapshot: true,
            fanHasSnapshot: { _ in false }
        )
        XCTAssertFalse(plan.capturesCenterBeforeLive)
    }

    func test_fanCaptureIsMissingOnly() {
        // Card 2 already cached; remaining fan slots still need capture.
        let plan = MapMediaRefreshPlanner.plan(
            centerIndex: 0,
            cardCount: 6,
            peekRadius: 5,
            layoutReady: true,
            centerHasSnapshot: true,
            fanHasSnapshot: { $0 == 2 }
        )
        XCTAssertEqual(Set(plan.fanCaptureIndices), Set([1, 3, 4, 5]))
        XCTAssertFalse(plan.fanCaptureIndices.contains(0), "center is never a fan index")
    }

    func test_radiusClampedToCardCount() {
        let plan = MapMediaRefreshPlanner.plan(
            centerIndex: 0,
            cardCount: 3,
            peekRadius: 99,
            layoutReady: true,
            centerHasSnapshot: true,
            fanHasSnapshot: { _ in false }
        )
        XCTAssertEqual(Set(plan.fanCaptureIndices), Set([1, 2]))
    }
}
