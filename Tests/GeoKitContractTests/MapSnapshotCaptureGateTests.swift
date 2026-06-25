import GeoKitContract
import XCTest

final class MapSnapshotCaptureGateTests: XCTestCase {
    func testMapboxRequiresLiveMapSafeWindow() {
        XCTAssertTrue(MapSnapshotCaptureGate.requiresLiveMapSafeWindow(for: .mapbox))
    }

    func testAppleDoesNotRequireLiveMapSafeWindow() {
        XCTAssertFalse(MapSnapshotCaptureGate.requiresLiveMapSafeWindow(for: .apple))
    }

    func testMapboxDefersWhileLiveMapActive() {
        XCTAssertTrue(MapSnapshotCaptureGate.shouldDeferCapture(provider: .mapbox, liveMapActive: true))
    }

    func testAppleCapturesWhileLiveMapActive() {
        XCTAssertFalse(MapSnapshotCaptureGate.shouldDeferCapture(provider: .apple, liveMapActive: true))
    }
}
