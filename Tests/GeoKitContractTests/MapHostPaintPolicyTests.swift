import GeoKitContract
import XCTest

final class MapHostPaintPolicyTests: XCTestCase {
    func testExpandedOverlaySkipsSnapshotBootstrap() {
        XCTAssertFalse(
            MapHostPaintPolicy.paintsInCardSnapshotBootstrap(
                isExpandedOverlay: true,
                isFocused: true,
                showsLiveHole: true,
                isLiveCard: true,
                hasCoverPoster: true,
                isCollapsing: true,
                isMapRendered: true
            )
        )
    }

    func testFocusedLiveHandoffSkipsInCardBootstrap() {
        XCTAssertFalse(
            MapHostPaintPolicy.paintsInCardSnapshotBootstrap(
                isExpandedOverlay: false,
                isFocused: true,
                showsLiveHole: true,
                isLiveCard: true,
                hasCoverPoster: true
            )
        )
    }

    func testFocusedCollapsedSlotNeverBootstrapsSnapshot() {
        XCTAssertFalse(
            MapHostPaintPolicy.paintsInCardSnapshotBootstrap(
                isExpandedOverlay: false,
                isFocused: true,
                showsLiveHole: false,
                isLiveCard: false,
                hasCoverPoster: false
            )
        )
    }

    func testExpandedOverlayTransparentHoleBeforeLivePaint() {
        XCTAssertEqual(
            MapHostPaintPolicy.hoistedHoleContent(
                showsTransparentRootLivePassThrough: false,
                paintsInlinePeekSnapshot: false,
                hasPeekSnapshot: false,
                hasGeneralCover: false,
                mediaLoadAllowed: true,
                isMapRendered: false,
                paintsVisibleInlineLiveMap: false,
                paintsInCardSnapshotBootstrap: false,
                isVisiblePeek: false,
                isExpandedOverlay: true,
                usesExternalLiveHost: true
            ),
            .transparentPassThrough
        )
    }

    func testExpandedOverlayDoesNotBootstrapSecondEngine() {
        XCTAssertFalse(
            MapHostPaintPolicy.paintsInCardSnapshotBootstrap(
                isExpandedOverlay: true,
                isFocused: true,
                showsLiveHole: true,
                isLiveCard: true,
                hasCoverPoster: false
            )
        )
    }
}
