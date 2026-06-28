import GeoKitContract
import XCTest

final class LiveMapSnapshotGateTests: XCTestCase {
    func testCanStartWhenNoLiveMapsAndNoGrace() {
        XCTAssertTrue(
            LiveMapSnapshotGate.canStartSnapshotCapture(
                liveMapCount: 0,
                isWithinMetalTeardownGrace: false
            )
        )
    }

    func testCannotStartWhileLiveMapMounted() {
        XCTAssertFalse(
            LiveMapSnapshotGate.canStartSnapshotCapture(
                liveMapCount: 1,
                isWithinMetalTeardownGrace: false
            )
        )
    }

    func testCannotStartDuringMetalTeardownGrace() {
        XCTAssertFalse(
            LiveMapSnapshotGate.canStartSnapshotCapture(
                liveMapCount: 0,
                isWithinMetalTeardownGrace: true
            )
        )
    }
}
