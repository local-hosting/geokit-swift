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

    func testSnapshotCoversLiveOnlyBeforeFirstPaintUnlessMorphFreeze() {
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
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.snapshotCoversLive(
                mapIsTransitioning: true,
                pinsLayoutSettling: false,
                livePainted: true,
                hasMorphFreeze: true
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

    func testLiveSurfaceCoverHeldUntilFirstLivePaintOrMorphFreeze() {
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.coversLiveSurface(livePainted: false)
        )
        XCTAssertFalse(
            MapPinTransitionCoverPolicy.coversLiveSurface(livePainted: true)
        )
        XCTAssertTrue(
            MapPinTransitionCoverPolicy.coversLiveSurface(
                livePainted: true,
                hasMorphFreeze: true
            )
        )
    }

    func testLiveSurfaceStaysCoveredUntilPaintedAndCentered() {
        XCTAssertFalse(
            LiveMapRevealPolicy.revealsLiveSurface(
                livePainted: true,
                cameraSettledAtTarget: false,
                isTransitioning: false
            )
        )
        XCTAssertTrue(
            LiveMapRevealPolicy.revealsLiveSurface(
                livePainted: true,
                cameraSettledAtTarget: true,
                isTransitioning: false
            )
        )
        XCTAssertFalse(
            LiveMapRevealPolicy.revealsLiveSurface(
                livePainted: false,
                cameraSettledAtTarget: true,
                isTransitioning: false
            )
        )
        // Mid expand/collapse without latch: host-driven reveal (cold / no capture).
        XCTAssertTrue(
            LiveMapRevealPolicy.revealsLiveSurface(
                livePainted: true,
                cameraSettledAtTarget: false,
                isTransitioning: true
            )
        )
        // Warm morph with live-frame latch: keep cover until latch clears.
        XCTAssertFalse(
            LiveMapRevealPolicy.revealsLiveSurface(
                livePainted: true,
                cameraSettledAtTarget: false,
                isTransitioning: true,
                hasMorphFreeze: true
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
