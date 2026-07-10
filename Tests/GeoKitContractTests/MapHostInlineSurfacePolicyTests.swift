import GeoKitContract
import XCTest

final class MapHostInlineSurfacePolicyTests: XCTestCase {
    func testCollapseUnmountsInlineLiveMap() {
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.keepsInlineLiveMapMounted(
                usesInlineLiveSlice: true,
                usesExternalLiveHost: true,
                isExpanded: false,
                isExpandedOverlay: false,
                isFocused: true,
                isLiveCard: true,
                mediaKeepAlive: false,
                isMapRendered: true,
                collectionExpanded: false,
                isCollapsing: true,
                isHeroFrameMorphing: false,
                collectionIsTransitioning: false,
                cardDragOffset: 0
            )
        )
    }

    func testExpandLiveHandoffKeepsInlineMountedDuringHeroMorph() {
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.keepsInlineLiveMapMounted(
                usesInlineLiveSlice: true,
                usesExternalLiveHost: true,
                isExpanded: false,
                isExpandedOverlay: false,
                isFocused: true,
                isLiveCard: true,
                mediaKeepAlive: false,
                isMapRendered: true,
                collectionExpanded: true,
                isCollapsing: false,
                isHeroFrameMorphing: true,
                collectionIsTransitioning: false,
                isExpandLiveHandoff: true,
                cardDragOffset: 0
            )
        )
    }

    func testTransparentPassThroughRequiresExpandedOverlayAndLivePaint() {
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.showsTransparentRootLivePassThrough(
                isExpandedOverlay: true,
                isMapRendered: true,
                rootHostOwnsLiveSurface: false
            )
        )
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.showsTransparentRootLivePassThrough(
                isExpandedOverlay: false,
                isMapRendered: true,
                rootHostOwnsLiveSurface: false
            )
        )
    }

    func testInlineLiveSliceIgnoresCollectionSwipeTransition() {
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.isTransitioning(
                usesInlineLiveSlice: true,
                isExpanded: false,
                isCollapsing: false,
                collectionIsTransitioning: true
            )
        )
    }
}
