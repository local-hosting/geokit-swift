import GeoKitContract
import XCTest

final class MapHostInlineSurfacePolicyTests: XCTestCase {

    func testCollapsedSkipsTransparentPassThroughEvenWhenLiveRendered() {
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.showsTransparentRootLivePassThrough(
                isExpandedOverlay: false,
                isMapRendered: true,
                rootHostOwnsLiveSurface: true
            )
        )
    }

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
                collectionExpanded: true,
                isCollapsing: false,
                isHeroFrameMorphing: true,
                collectionIsTransitioning: false,
                isExpandLiveHandoff: true,
                cardDragOffset: 0
            )
        )
    }




    func testCollapseMorphUsesInCardPosterWhenItMatchesLiveCamera() {
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.keepsExpandedOverlaySnapshotDuringMorph(
                isExpandedOverlay: true,
                isCollapsing: true,
                isCollapseLiveHandoff: false,
                isHeroFrameMorphing: false,
                isExpandLiveHandoff: false,
                isTransitioning: true,
                isMapRendered: true,
                collapsePosterMatchesLiveCamera: true
            )
        )
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.showsTransparentRootLivePassThrough(
                isExpandedOverlay: true,
                isMapRendered: true,
                rootHostOwnsLiveSurface: false,
                isCollapsing: true,
                isTransitioning: true,
                collapsePosterMatchesLiveCamera: true
            )
        )
    }

    func testCollapseMorphKeepsLivePassThroughUntilPosterLands() {
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.keepsExpandedOverlaySnapshotDuringMorph(
                isExpandedOverlay: true,
                isCollapsing: true,
                isCollapseLiveHandoff: false,
                isHeroFrameMorphing: false,
                isExpandLiveHandoff: false,
                isTransitioning: true,
                isMapRendered: true
            )
        )
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.showsTransparentRootLivePassThrough(
                isExpandedOverlay: true,
                isMapRendered: true,
                rootHostOwnsLiveSurface: false,
                isCollapsing: true,
                isTransitioning: true
            )
        )
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.keepsExpandedOverlaySnapshotDuringMorph(
                isExpandedOverlay: true,
                isCollapsing: true,
                isCollapseLiveHandoff: false,
                isHeroFrameMorphing: false,
                isExpandLiveHandoff: false,
                isTransitioning: true,
                isMapRendered: false
            )
        )
    }

    func testExpandMorphKeepsSnapshotInHoleInsteadOfTransparentPassThrough() {
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.keepsExpandedOverlaySnapshotDuringMorph(
                isExpandedOverlay: true,
                isCollapsing: false,
                isCollapseLiveHandoff: false,
                isHeroFrameMorphing: true,
                isExpandLiveHandoff: false,
                isTransitioning: false
            )
        )
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.showsTransparentRootLivePassThrough(
                isExpandedOverlay: true,
                isMapRendered: true,
                rootHostOwnsLiveSurface: false,
                isHeroFrameMorphing: true
            )
        )
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.showsTransparentRootLivePassThrough(
                isExpandedOverlay: true,
                isMapRendered: true,
                rootHostOwnsLiveSurface: false
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


    func testHoistedGeoKitTransitioningCoversWarmExpandAndCollapse() {
        // Warm live + hero morph (expand or collapse): must report transitioning for freeze latch.
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.hoistedGeoKitIsTransitioning(
                isHeroMorphing: true,
                isMapRendered: true,
                mapIsTransitioning: false
            )
        )
        // Settled live / card drag alone: no hero morph → no freeze latch.
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.hoistedGeoKitIsTransitioning(
                isHeroMorphing: false,
                isMapRendered: true,
                mapIsTransitioning: false
            )
        )
        // Cold load still transitions when the collection says so.
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.hoistedGeoKitIsTransitioning(
                isHeroMorphing: false,
                isMapRendered: false,
                mapIsTransitioning: true
            )
        )
    }



    func testInlineLiveMapStaysMountedWhileCardDragging() {
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.keepsInlineLiveMapMounted(
                usesInlineLiveSlice: true,
                usesExternalLiveHost: true,
                isExpanded: false,
                isExpandedOverlay: false,
                isFocused: true,
                isLiveCard: false,
                mediaKeepAlive: false,
                isMapRendered: true,
                collectionExpanded: false,
                isCollapsing: false,
                isHeroFrameMorphing: false,
                collectionIsTransitioning: false,
                cardDragOffset: 0
            )
        )
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
                collectionExpanded: false,
                isCollapsing: false,
                isHeroFrameMorphing: false,
                collectionIsTransitioning: false,
                cardDragOffset: 0
            )
        )
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
                isCollapsing: false,
                isHeroFrameMorphing: false,
                collectionIsTransitioning: false,
                cardDragOffset: 24
            )
        )
    }



    func testOnlyFocusedSettledCardMountsInlineLiveMap() {
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.keepsInlineLiveMapMounted(
                usesInlineLiveSlice: true,
                usesExternalLiveHost: true,
                isExpanded: false,
                isExpandedOverlay: false,
                isFocused: false,
                isLiveCard: true,
                mediaKeepAlive: true,
                isMapRendered: true,
                collectionExpanded: false,
                isCollapsing: false,
                isHeroFrameMorphing: false,
                collectionIsTransitioning: false,
                cardDragOffset: 0
            )
        )
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
                isCollapsing: false,
                isHeroFrameMorphing: false,
                collectionIsTransitioning: true,
                cardDragOffset: 0
            )
        )
    }

    func testInlineLiveMapNeverMountsVideoStyle() {
        XCTAssertFalse(
            MapHostInlineSurfacePolicy.keepsInlineLiveMapMounted(
                usesInlineLiveSlice: true,
                usesExternalLiveHost: true,
                isExpanded: true,
                isExpandedOverlay: true,
                isFocused: true,
                isLiveCard: true,
                mediaKeepAlive: false,
                isMapRendered: false,
                collectionExpanded: true,
                isCollapsing: false,
                isHeroFrameMorphing: false,
                collectionIsTransitioning: false,
                cardDragOffset: 0
            )
        )
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
                isCollapsing: false,
                isHeroFrameMorphing: false,
                collectionIsTransitioning: false,
                cardDragOffset: 0
            )
        )
    }



    func testCollapsedFocusedStackMountsInlineLiveWhenLiveOwner() {
        XCTAssertTrue(
            MapHostInlineSurfacePolicy.keepsInlineLiveMapMounted(
                usesInlineLiveSlice: true,
                usesExternalLiveHost: true,
                isExpanded: false,
                isExpandedOverlay: false,
                isFocused: true,
                isLiveCard: true,
                mediaKeepAlive: false,
                isMapRendered: false,
                collectionExpanded: false,
                isCollapsing: false,
                isHeroFrameMorphing: false,
                collectionIsTransitioning: false,
                cardDragOffset: 0
            )
        )
    }

}
