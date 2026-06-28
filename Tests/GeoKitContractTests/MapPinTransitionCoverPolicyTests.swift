import CoreGraphics
import GeoKitContract
import XCTest

final class MapPinTransitionCoverPolicyTests: XCTestCase {
    func testHideLiveMapPinsDuringTransitionOrSettling() {
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.hideLiveMapPins(
                mapIsTransitioning: true,
                pinsLayoutSettling: false
            )
        )
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.hideLiveMapPins(
                mapIsTransitioning: false,
                pinsLayoutSettling: true
            )
        )
        XCTAssertFalse(
            MapPinTransitionCoverPolicy.hideLiveMapPins(
                mapIsTransitioning: false,
                pinsLayoutSettling: false
            )
        )
    }

    func testSnapshotCoversLiveWhileTransitioningOrSettling() {
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.snapshotCoversLive(
                mapIsTransitioning: true,
                pinsLayoutSettling: false,
                livePainted: true
            )
        )
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.snapshotCoversLive(
                mapIsTransitioning: false,
                pinsLayoutSettling: true,
                livePainted: true
            )
        )
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.snapshotCoversLive(
                mapIsTransitioning: false,
                pinsLayoutSettling: false,
                livePainted: false
            )
        )
        XCTAssertFalse(
            MapPinTransitionCoverPolicy.snapshotCoversLive(
                mapIsTransitioning: false,
                pinsLayoutSettling: false,
                livePainted: true
            )
        )
    }

    func testLayoutSettlingBeginsAfterValidResizeWhenNotTransitioning() {
        let previous = CGSize(width: 320, height: 420)
        let next = CGSize(width: 390, height: 844)

        XCTAssertTrue(
            MapPinLayoutSettlingPolicy.shouldBeginSettling(
                isTransitioning: false,
                previousSize: previous,
                newSize: next,
                mapReady: true
            )
        )
        XCTAssertFalse(
            MapPinLayoutSettlingPolicy.shouldBeginSettling(
                isTransitioning: true,
                previousSize: previous,
                newSize: next,
                mapReady: true
            )
        )
        XCTAssertFalse(
            MapPinLayoutSettlingPolicy.shouldBeginSettling(
                isTransitioning: false,
                previousSize: previous,
                newSize: previous,
                mapReady: true
            )
        )
        XCTAssertFalse(
            MapPinLayoutSettlingPolicy.shouldBeginSettling(
                isTransitioning: false,
                previousSize: .zero,
                newSize: next,
                mapReady: true
            )
        )
    }
}
