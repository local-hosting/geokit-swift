import GeoKitContract
import XCTest

final class MapboxLiveMapSnapshotGateTests: XCTestCase {
    func testCanStartWhenNoLiveMapsAndNoGrace() {
        XCTAssertTrue(
            MapboxLiveMapSnapshotGate.canStartSnapshotCapture(
                liveMapCount: 0,
                isWithinMetalTeardownGrace: false
            )
        )
    }

    func testCannotStartWhileLiveMapMounted() {
        XCTAssertFalse(
            MapboxLiveMapSnapshotGate.canStartSnapshotCapture(
                liveMapCount: 1,
                isWithinMetalTeardownGrace: false
            )
        )
    }

    func testCannotStartDuringMetalTeardownGrace() {
        XCTAssertFalse(
            MapboxLiveMapSnapshotGate.canStartSnapshotCapture(
                liveMapCount: 0,
                isWithinMetalTeardownGrace: true
            )
        )
    }
}
