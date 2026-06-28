import GeoKitContract
import XCTest

final class GeoKitCardMediaStateTests: XCTestCase {

    func testFanPeekDragWarmUsesLiveMode() {
        let mode = GeoKitCardMediaModeResolver.resolve(
            role: .fanPeek,
            isLiveEnabled: true,
            isMapRendered: false,
            hasSnapshot: true,
            isTransitioning: false
        )
        XCTAssertEqual(mode, .live)
    }

    func testCenterRoleWhenCenteredAndCollapsed() {
        let role = GeoKitCardSlotRoleResolver.role(
            isCentered: true,
            stackOffset: 0,
            collectionExpanded: false,
            isCollapsing: false,
            isExpandedOverlay: false
        )
        XCTAssertEqual(role, .center)
    }

    func testExpandedOverlayRole() {
        let role = GeoKitCardSlotRoleResolver.role(
            isCentered: true,
            stackOffset: 0,
            collectionExpanded: true,
            isCollapsing: false,
            isExpandedOverlay: true
        )
        XCTAssertEqual(role, .expandedOverlay)
    }

    func testFanPeekRoleWithinRadius() {
        let role = GeoKitCardSlotRoleResolver.role(
            isCentered: false,
            stackOffset: 2,
            collectionExpanded: false,
            isCollapsing: false,
            isExpandedOverlay: false,
            peekRadius: 5
        )
        XCTAssertEqual(role, .fanPeek)
    }

    func testHiddenWhenCollectionExpandedAndNotOverlay() {
        let role = GeoKitCardSlotRoleResolver.role(
            isCentered: true,
            stackOffset: 0,
            collectionExpanded: true,
            isCollapsing: false,
            isExpandedOverlay: false
        )
        XCTAssertEqual(role, .hidden)
    }

    func testLiveModeWhenCenterLiveEnabled() {
        let mode = GeoKitCardMediaModeResolver.resolve(
            role: .center,
            isLiveEnabled: true,
            isMapRendered: false,
            hasSnapshot: false,
            isTransitioning: false
        )
        XCTAssertEqual(mode, .live)
    }

    func testSnapshotDuringExpandedSpring() {
        let mode = GeoKitCardMediaModeResolver.resolve(
            role: .expandedOverlay,
            isLiveEnabled: true,
            isMapRendered: false,
            hasSnapshot: true,
            isTransitioning: true
        )
        XCTAssertEqual(mode, .snapshot)
    }

    func testFanPeekUsesSnapshotWhenAvailable() {
        let mode = GeoKitCardMediaModeResolver.resolve(
            role: .fanPeek,
            isLiveEnabled: false,
            isMapRendered: false,
            hasSnapshot: true,
            isTransitioning: false
        )
        XCTAssertEqual(mode, .snapshot)
    }

    func testPresentationContextMediaModeMatchesPolicy() {
        let ctx = MapCardMediaPresentationContext(
            isStackCenter: true,
            isStackOneBehind: false,
            collectionExpanded: false,
            isExpandedOverlaySlot: false,
            cardIsTransitioning: false,
            cardIsCollapsing: false,
            isLiveEnabled: true,
            isMapRendered: false,
            hasActiveSnapshot: false,
            isCenteredInStack: true
        )
        XCTAssertEqual(ctx.mediaMode, .live)
        XCTAssertTrue(MapCardMediaPresentationPolicy.showsLiveMap(ctx))
    }
}
