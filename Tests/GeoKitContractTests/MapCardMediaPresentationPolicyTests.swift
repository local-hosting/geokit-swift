import CoreGraphics
import GeoKitContract
import XCTest

final class MapCardMediaPresentationPolicyTests: XCTestCase {
    private func context(
        isStackCenter: Bool = false,
        isStackOneBehind: Bool = false,
        collectionExpanded: Bool = false,
        isExpandedOverlaySlot: Bool = false,
        cardIsTransitioning: Bool = false,
        cardIsCollapsing: Bool = false,
        isLiveEnabled: Bool = false,
        isMapRendered: Bool = false,
        hasActiveSnapshot: Bool = false,
        isCenteredInStack: Bool = false
    ) -> MapCardMediaPresentationContext {
        MapCardMediaPresentationContext(
            isStackCenter: isStackCenter,
            isStackOneBehind: isStackOneBehind,
            collectionExpanded: collectionExpanded,
            isExpandedOverlaySlot: isExpandedOverlaySlot,
            cardIsTransitioning: cardIsTransitioning,
            cardIsCollapsing: cardIsCollapsing,
            isLiveEnabled: isLiveEnabled,
            isMapRendered: isMapRendered,
            hasActiveSnapshot: hasActiveSnapshot,
            isCenteredInStack: isCenteredInStack
        )
    }

    func testLiveWarmupWithoutCameraIsTransitioningNotLoading() {
        let ctx = context(
            isStackCenter: true,
            isLiveEnabled: true,
            isMapRendered: false,
            hasActiveSnapshot: false
        )

        XCTAssertTrue(MapCardMediaPresentationPolicy.showsLiveMap(ctx))
        XCTAssertTrue(MapCardMediaPresentationPolicy.mapIsTransitioning(ctx))
        XCTAssertTrue(MapCardMediaPresentationPolicy.liveMapVisible(ctx))
        XCTAssertFalse(MapCardMediaPresentationPolicy.shouldShowLoadingOverlay(ctx))
    }

    func testLiveWarmupWithoutCameraWouldShowLoadingIfTransitionIgnored() {
        let ctx = context(
            isStackCenter: true,
            isLiveEnabled: true,
            isMapRendered: false,
            hasActiveSnapshot: false
        )

        let ignoringLiveWarmup = !MapCardMediaPresentationPolicy.liveMapVisible(ctx)
            && !ctx.hasActiveSnapshot
            && ctx.isStackCenter

        XCTAssertFalse(
            ignoringLiveWarmup,
            "regression: live-enabled center slot must not fall back to loading while map warms up"
        )
    }

    func testSnapshotSuppressesLoadingBeforeLivePaint() {
        let ctx = context(
            isStackCenter: true,
            isLiveEnabled: true,
            isMapRendered: false,
            hasActiveSnapshot: true
        )

        XCTAssertFalse(MapCardMediaPresentationPolicy.shouldShowLoadingOverlay(ctx))
        XCTAssertTrue(MapCardMediaPresentationPolicy.mapIsTransitioning(ctx))
    }

    func testPaintedLiveMapVisible() {
        let ctx = context(
            isStackCenter: true,
            isLiveEnabled: true,
            isMapRendered: true
        )

        XCTAssertTrue(MapCardMediaPresentationPolicy.liveMapVisible(ctx))
        XCTAssertFalse(MapCardMediaPresentationPolicy.shouldShowLoadingOverlay(ctx))
    }

    func testExpandedOverlayReportsSurfaceFrameNotHiddenStackCenter() {
        let hiddenCenter = context(
            isStackCenter: true,
            collectionExpanded: true,
            isExpandedOverlaySlot: false,
            isLiveEnabled: true,
            isCenteredInStack: true
        )
        let overlay = context(
            collectionExpanded: true,
            isExpandedOverlaySlot: true,
            isLiveEnabled: true
        )

        XCTAssertFalse(MapCardMediaPresentationPolicy.reportsMediaSurfaceFrame(hiddenCenter))
        XCTAssertTrue(MapCardMediaPresentationPolicy.reportsMediaSurfaceFrame(overlay))
    }

    func testHiddenStackCenterDoesNotReportWhileCollectionExpanded() {
        let ctx = context(
            isStackCenter: true,
            collectionExpanded: true,
            isExpandedOverlaySlot: false,
            cardIsTransitioning: true,
            isLiveEnabled: true,
            isCenteredInStack: true
        )

        XCTAssertFalse(MapCardMediaPresentationPolicy.reportsMediaSurfaceFrame(ctx))
    }

    func testBackCardWithoutSnapshotShowsLoading() {
        let ctx = context(isStackOneBehind: true, hasActiveSnapshot: false)

        XCTAssertTrue(MapCardMediaPresentationPolicy.shouldShowLoadingOverlay(ctx))
        XCTAssertFalse(MapCardMediaPresentationPolicy.showsLiveMap(ctx))
    }

    func testLiveCenterWaitingForRenderHidesLoadingOverlay() {
        let ctx = context(isStackCenter: true, isLiveEnabled: true, isMapRendered: false, hasActiveSnapshot: false)

        XCTAssertFalse(MapCardMediaPresentationPolicy.shouldShowLoadingOverlay(ctx))
    }

    func testNonLiveCenterWaitingForSnapshotShowsLoading() {
        let ctx = context(isStackCenter: true, isLiveEnabled: false, hasActiveSnapshot: false)

        XCTAssertTrue(MapCardMediaPresentationPolicy.shouldShowLoadingOverlay(ctx))
    }

    func testOnlyExpandedOverlayAllowsLiveWhenCollectionExpanded() {
        let collapsedSlot = context(isStackCenter: true, collectionExpanded: true, isExpandedOverlaySlot: false)
        let overlay = context(collectionExpanded: true, isExpandedOverlaySlot: true)

        XCTAssertFalse(MapCardMediaPresentationPolicy.allowsLiveMount(collapsedSlot))
        XCTAssertTrue(MapCardMediaPresentationPolicy.allowsLiveMount(overlay))
    }

    func testStackCenterDoesNotAllowLiveMountDuringCollapse() {
        let ctx = context(
            isStackCenter: true,
            collectionExpanded: true,
            isExpandedOverlaySlot: false,
            cardIsCollapsing: true,
            isLiveEnabled: true
        )

        XCTAssertFalse(MapCardMediaPresentationPolicy.allowsLiveMount(ctx))
    }

    func testExpandedOverlayDefersLiveDuringSpringWhenSnapshotReady() {
        let overlay = context(
            collectionExpanded: true,
            isExpandedOverlaySlot: true,
            cardIsTransitioning: true,
            isLiveEnabled: true,
            isMapRendered: false,
            hasActiveSnapshot: true
        )

        XCTAssertFalse(MapCardMediaPresentationPolicy.showsLiveMap(overlay))
        XCTAssertFalse(MapCardMediaPresentationPolicy.liveMapVisible(overlay))
    }

    func testExpandedOverlayMountsLiveAfterSpringWhenSnapshotReady() {
        let overlay = context(
            collectionExpanded: true,
            isExpandedOverlaySlot: true,
            cardIsTransitioning: false,
            isLiveEnabled: true,
            isMapRendered: false,
            hasActiveSnapshot: true
        )

        XCTAssertTrue(MapCardMediaPresentationPolicy.showsLiveMap(overlay))
    }

    func testSnapshotLoadAllowedForCenterWithoutSnapshot() {
        XCTAssertTrue(
            MapCardMediaPresentationPolicy.snapshotLoadAllowed(
                isExpandedOverlaySlot: false,
                isSnapshotBootstrapping: false,
                mediaLoadAllowed: false,
                isStackCenter: true,
                isStackOneBehind: false,
                hasActiveSnapshot: false
            )
        )
    }

    func testSnapshotLoadBlockedWhileBootstrapping() {
        XCTAssertFalse(
            MapCardMediaPresentationPolicy.snapshotLoadAllowed(
                isExpandedOverlaySlot: false,
                isSnapshotBootstrapping: true,
                mediaLoadAllowed: true,
                isStackCenter: true,
                isStackOneBehind: false,
                hasActiveSnapshot: false
            )
        )
    }

    func testLiveWarmupVisibleDoesNotImplyHostFrameReady() {
        let ctx = context(
            isStackCenter: true,
            isLiveEnabled: true,
            isMapRendered: false,
            hasActiveSnapshot: false
        )

        XCTAssertTrue(MapCardMediaPresentationPolicy.liveMapVisible(ctx))
        XCTAssertFalse(MapLiveSurfaceFrameResolver.isValidHostFrame(.zero))
    }


    func testFanPeekShowsLiveWhenDragWarmEnabled() {
        let ctx = context(
            isStackCenter: false,
            isStackOneBehind: true,
            isLiveEnabled: true,
            isMapRendered: true
        )
        XCTAssertFalse(MapCardMediaPresentationPolicy.allowsLiveMount(ctx))
        XCTAssertTrue(MapCardMediaPresentationPolicy.showsLiveMap(ctx))
        XCTAssertTrue(
            MapCardMediaPresentationPolicy.isLiveDataEnabled(
                liveCardID: "center",
                warmLiveCardID: "nyc",
                cardID: "nyc",
                allowsLiveMount: false
            )
        )
    }

    func testOnlyTopSlotResolvesLiveData() {
        XCTAssertTrue(
            MapCardMediaPresentationPolicy.isLiveDataEnabled(
                liveCardID: "nyc",
                cardID: "nyc",
                allowsLiveMount: true
            )
        )
        XCTAssertFalse(
            MapCardMediaPresentationPolicy.isLiveDataEnabled(
                liveCardID: "nyc",
                cardID: "louisville",
                allowsLiveMount: true
            )
        )
    }

    func testExternalHostUsesTransparentBackdropWhileLoading() {
        XCTAssertTrue(
            MapCardMediaPresentationPolicy.usesTransparentExternalHostBackdrop(
                externalLiveMapHost: true,
                showsPaintedLiveMap: true
            )
        )
        XCTAssertTrue(
            MapCardMediaPresentationPolicy.usesTransparentExternalHostBackdrop(
                externalLiveMapHost: true,
                showsPaintedLiveMap: false
            )
        )
        XCTAssertFalse(
            MapCardMediaPresentationPolicy.usesTransparentExternalHostBackdrop(
                externalLiveMapHost: false,
                showsPaintedLiveMap: true
            )
        )
    }
}

final class MapLiveSurfaceFrameResolverTests: XCTestCase {
    func testPrefersReportedFrame() {
        let reported = CGRect(x: 10, y: 20, width: 300, height: 420)
        let collapsed = CGRect(x: 0, y: 0, width: 320, height: 480)

        XCTAssertEqual(
            MapLiveSurfaceFrameResolver.resolve(reportedFrame: reported, collapsedCardFrame: collapsed),
            reported
        )
    }

    func testFallbackUsesFullBleedCollapsedFrame() {
        let collapsed = CGRect(x: 8, y: 16, width: 320, height: 480)
        let resolved = MapLiveSurfaceFrameResolver.resolve(
            reportedFrame: .zero,
            collapsedCardFrame: collapsed,
            mediaSurfaceFooterInset: 48
        )
        XCTAssertEqual(resolved, collapsed)
    }

    func testFallsBackToCollapsedCardBeforePreferenceArrives() {
        let collapsed = CGRect(x: 8, y: 16, width: 320, height: 480)

        XCTAssertEqual(
            MapLiveSurfaceFrameResolver.resolve(reportedFrame: .zero, collapsedCardFrame: collapsed),
            collapsed
        )
    }

    func testInvalidFramesReturnZero() {
        XCTAssertEqual(
            MapLiveSurfaceFrameResolver.resolve(reportedFrame: .zero, collapsedCardFrame: .zero),
            .zero
        )
        XCTAssertFalse(MapLiveSurfaceFrameResolver.isValidHostFrame(.zero))
        XCTAssertTrue(MapLiveSurfaceFrameResolver.isValidHostFrame(CGRect(x: 0, y: 0, width: 100, height: 200)))
    }
}

final class MapLiveCardSelectionPolicyTests: XCTestCase {
    func testAssignsLiveWhenSnapshotReady() {
        XCTAssertEqual(
            MapLiveCardSelectionPolicy.liveCardID(
                centerCardID: "louisville",
                centerHasUsableSnapshot: true,
                centerMapRendered: false
            ),
            "louisville"
        )
    }

    func testKeepsLiveWhenMapRenderedAfterCameraDrift() {
        XCTAssertEqual(
            MapLiveCardSelectionPolicy.liveCardID(
                centerCardID: "louisville",
                centerHasUsableSnapshot: false,
                centerMapRendered: true
            ),
            "louisville"
        )
    }

    func testAssignsLiveEvenBeforeSnapshotOrRender() {
        XCTAssertEqual(
            MapLiveCardSelectionPolicy.liveCardID(
                centerCardID: "louisville",
                centerHasUsableSnapshot: false,
                centerMapRendered: false
            ),
            "louisville"
        )
    }
}

final class MapLiveSurfaceCenterFrameTests: XCTestCase {
    func testGlobalFrameRoundTripUsesCenterOrigin() {
        let source = CGRect(x: 40, y: 120, width: 320, height: 420)
        let center = MapLiveSurfaceCenterFrame(globalFrame: source)
        XCTAssertEqual(center.centerX, source.midX, accuracy: 0.001)
        XCTAssertEqual(center.centerY, source.midY, accuracy: 0.001)
        let roundTrip = center.globalFrame
        XCTAssertEqual(roundTrip.origin.x, source.origin.x, accuracy: 0.001)
        XCTAssertEqual(roundTrip.origin.y, source.origin.y, accuracy: 0.001)
        XCTAssertEqual(roundTrip.size.width, source.size.width, accuracy: 0.001)
        XCTAssertEqual(roundTrip.size.height, source.size.height, accuracy: 0.001)
    }
}

final class MapMediaSurfaceLayoutTests: XCTestCase {
    func testMapContentSizeIsFullBleed() {
        let size = CGSize(width: 320, height: 480)
        XCTAssertEqual(
            MapMediaSurfaceLayout.mapContentSize(cardContentSize: size, mediaSurfaceFooterInset: 48),
            size
        )
        XCTAssertEqual(
            MapMediaSurfaceLayout.mapContentSize(cardContentSize: size, mediaSurfaceFooterInset: 500),
            size
        )
    }
}
