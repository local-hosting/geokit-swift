import CoreGraphics
import GeoKitContract
import XCTest

final class MapPinTransitionCoverPolicyTests: XCTestCase {
    func testLivePinsStayMountedDuringTransitionAndSettling() {
        XCTAssertFalse(
            MapPinTransitionCoverPolicy.hideLiveMapPins(
                mapIsTransitioning: true,
                pinsLayoutSettling: false
            )
        )
        XCTAssertFalse(
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

    func testSnapshotCoversLiveOnlyBeforeFirstPaint() {
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.snapshotCoversLive(
                mapIsTransitioning: true,
                pinsLayoutSettling: false,
                livePainted: false
            )
        )
        XCTAssertFalse(
            MapPinTransitionCoverPolicy.snapshotCoversLive(
                mapIsTransitioning: true,
                pinsLayoutSettling: false,
                livePainted: true
            )
        )
        XCTAssertFalse(
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
    }

    func testWhiteBaseCoverHeldUntilFirstLivePaintWithoutSnapshot() {
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.coversLiveSurfaceWhiteBase(
                showMap: true,
                livePainted: false,
                hasFrozenSnapshot: false
            )
        )
        XCTAssertFalse(
            MapPinTransitionCoverPolicy.coversLiveSurfaceWhiteBase(
                showMap: true,
                livePainted: true,
                hasFrozenSnapshot: false
            )
        )
        XCTAssertFalse(
            MapPinTransitionCoverPolicy.coversLiveSurfaceWhiteBase(
                showMap: true,
                livePainted: false,
                hasFrozenSnapshot: true
            )
        )
        XCTAssertFalse(
            MapPinTransitionCoverPolicy.coversLiveSurfaceWhiteBase(
                showMap: false,
                livePainted: false,
                hasFrozenSnapshot: false
            )
        )
    }

    func testLiveSurfaceStaysCoveredUntilPaintedAndCentered() {
        // Painted but not yet centered: the first idle fired at the default camera, cover must hold.
        XCTAssertFalse(
            LiveMapRevealPolicy.revealsLiveSurface(
                livePainted: true,
                cameraSettledAtTarget: false,
                isTransitioning: false
            )
        )
        // Painted and centered on the pins: safe to reveal.
        XCTAssertTrue(
            LiveMapRevealPolicy.revealsLiveSurface(
                livePainted: true,
                cameraSettledAtTarget: true,
                isTransitioning: false
            )
        )
        // Not painted yet: never reveal, regardless of camera.
        XCTAssertFalse(
            LiveMapRevealPolicy.revealsLiveSurface(
                livePainted: false,
                cameraSettledAtTarget: true,
                isTransitioning: false
            )
        )
        // Mid expand/collapse: host drives framing, so painted alone reveals without waiting on settle.
        XCTAssertTrue(
            LiveMapRevealPolicy.revealsLiveSurface(
                livePainted: true,
                cameraSettledAtTarget: false,
                isTransitioning: true
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
                previousSize: previous,
                newSize: CGSize(width: previous.width + 1, height: previous.height + 1),
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
