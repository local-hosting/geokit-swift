import GeoKitContract
import XCTest

final class MapSnapshotRetryPolicyTests: XCTestCase {
    func testSkipWhenSnapshotExists() {
        XCTAssertEqual(
            MapSnapshotRetryPolicy.nextAction(
                hasSnapshot: true,
                isPrefetchScheduled: false,
                provider: .mapbox,
                canStartSnapshotCapture: true,
                isOnline: true
            ),
            .skip
        )
    }

    func testSkipWhenPrefetchScheduled() {
        XCTAssertEqual(
            MapSnapshotRetryPolicy.nextAction(
                hasSnapshot: false,
                isPrefetchScheduled: true,
                provider: .mapbox,
                canStartSnapshotCapture: true,
                isOnline: true
            ),
            .skip
        )
    }

    func testWaitForNetworkWhenOffline() {
        XCTAssertEqual(
            MapSnapshotRetryPolicy.nextAction(
                hasSnapshot: false,
                isPrefetchScheduled: false,
                provider: .mapbox,
                canStartSnapshotCapture: true,
                isOnline: false
            ),
            .waitForNetwork
        )
    }

    func testWaitForLiveMapSafeWhenMapboxBlocked() {
        XCTAssertEqual(
            MapSnapshotRetryPolicy.nextAction(
                hasSnapshot: false,
                isPrefetchScheduled: false,
                provider: .mapbox,
                canStartSnapshotCapture: false,
                isOnline: true
            ),
            .waitForLiveMapSafe
        )
    }

    func testCaptureWhenReady() {
        XCTAssertEqual(
            MapSnapshotRetryPolicy.nextAction(
                hasSnapshot: false,
                isPrefetchScheduled: false,
                provider: .apple,
                canStartSnapshotCapture: false,
                isOnline: true
            ),
            .capture
        )
    }
}
