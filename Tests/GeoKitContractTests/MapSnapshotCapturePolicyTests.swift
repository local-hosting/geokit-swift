import GeoKitContract
import XCTest

final class MapSnapshotCapturePolicyTests: XCTestCase {
    func testMapboxAndAppleShareTwoAttemptBudget() {
        XCTAssertEqual(MapSnapshotCapturePolicy.maxAttempts, 2)
    }

    func testSchedulesRetryAfterFirstFailureOnly() {
        XCTAssertTrue(MapSnapshotCapturePolicy.shouldScheduleRetry(failureCount: 1))
        XCTAssertFalse(MapSnapshotCapturePolicy.shouldScheduleRetry(failureCount: 2))
        XCTAssertFalse(MapSnapshotCapturePolicy.shouldScheduleRetry(failureCount: 3))
    }

    func testRetryDelayMatchesCollapsedMapboxView() {
        XCTAssertEqual(MapSnapshotCapturePolicy.retryDelayMilliseconds, 400)
    }
}
