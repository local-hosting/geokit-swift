import CoreGraphics
import GeoKitContract
import XCTest

final class MapSnapshotRefreshPlanTests: XCTestCase {
    func testSkipsRefreshWhenLayoutTooSmall() {
        XCTAssertFalse(
            MapSnapshotRefreshPlan.shouldRefresh(
                layoutSize: CGSize(width: 64, height: 200),
                cacheKey: "a",
                lastCacheKey: nil,
                hasSnapshot: false
            )
        )
    }

    func testSkipsRefreshWhenCacheHitHasSnapshot() {
        XCTAssertFalse(
            MapSnapshotRefreshPlan.shouldRefresh(
                layoutSize: CGSize(width: 200, height: 200),
                cacheKey: "same",
                lastCacheKey: "same",
                hasSnapshot: true
            )
        )
    }

    func testRefreshesWhenCacheKeyChanges() {
        XCTAssertTrue(
            MapSnapshotRefreshPlan.shouldRefresh(
                layoutSize: CGSize(width: 200, height: 200),
                cacheKey: "new",
                lastCacheKey: "old",
                hasSnapshot: true
            )
        )
    }

    func testShowsPlaceholderAfterExhaustedCaptureWithoutSnapshot() {
        XCTAssertTrue(
            MapSnapshotRefreshPlan.shouldShowFailedCapturePlaceholder(
                hasSnapshot: false,
                captureAttemptsExhausted: true
            )
        )
        XCTAssertFalse(
            MapSnapshotRefreshPlan.shouldShowFailedCapturePlaceholder(
                hasSnapshot: true,
                captureAttemptsExhausted: true
            )
        )
        XCTAssertFalse(
            MapSnapshotRefreshPlan.shouldShowFailedCapturePlaceholder(
                hasSnapshot: false,
                captureAttemptsExhausted: false
            )
        )
    }
}
