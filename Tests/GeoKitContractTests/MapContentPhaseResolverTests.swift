import GeoKitContract
import XCTest

final class MapContentPhaseResolverTests: XCTestCase {
    func testPeekWithoutSnapshotUsesPlaceholder() {
        let policy = MapStagePolicy(stage: .peek, isExpanded: false)
        let lifecycle = MapLifecycleState(hasSnapshot: false, isStyleReady: false, isSurfaceReady: true)
        XCTAssertEqual(
            MapContentPhaseResolver.resolve(MapLifecycleInput(policy: policy, lifecycle: lifecycle)),
            .placeholder
        )
    }

    func testPeekWithSnapshotUsesSnapshot() {
        let policy = MapStagePolicy(stage: .peek, isExpanded: false)
        let lifecycle = MapLifecycleState(hasSnapshot: true, isStyleReady: false, isSurfaceReady: true)
        XCTAssertEqual(
            MapContentPhaseResolver.resolve(MapLifecycleInput(policy: policy, lifecycle: lifecycle)),
            .snapshot
        )
    }

    func testCenterUsesLiveWhenReady() {
        let policy = MapStagePolicy(stage: .center, isExpanded: false)
        let lifecycle = MapLifecycleState(hasSnapshot: true, isStyleReady: true, isSurfaceReady: true)
        XCTAssertEqual(
            MapContentPhaseResolver.resolve(MapLifecycleInput(policy: policy, lifecycle: lifecycle)),
            .live
        )
    }

    func testTransitionUsesSnapshotOverlay() {
        let policy = MapStagePolicy(stage: .expand, isExpanded: true)
        let lifecycle = MapLifecycleState(hasSnapshot: true, isStyleReady: true, isSurfaceReady: true, isTransitioning: true)
        XCTAssertEqual(
            MapContentPhaseResolver.resolve(MapLifecycleInput(policy: policy, lifecycle: lifecycle)),
            .snapshot
        )
    }

    func testSurfaceNotReadyUsesPlaceholder() {
        let policy = MapStagePolicy(stage: .center, isExpanded: false)
        let lifecycle = MapLifecycleState(hasSnapshot: true, isStyleReady: true, isSurfaceReady: false)
        XCTAssertEqual(
            MapContentPhaseResolver.resolve(MapLifecycleInput(policy: policy, lifecycle: lifecycle)),
            .placeholder
        )
    }

    func testRequestBuilderUsesResolvedPhase() {
        let request = MapContentRequestBuilder.make(
            id: "card-1",
            policy: MapStagePolicy(stage: .center, isExpanded: false),
            lifecycle: MapLifecycleState(hasSnapshot: true, isStyleReady: true, isSurfaceReady: true),
            isExpanded: false,
            title: "Map"
        )
        XCTAssertEqual(request.phase, .live)
        XCTAssertEqual(request.id, "card-1")
    }

    func testMaxActiveMapsMatchesNodeBudget() {
        XCTAssertEqual(GeoKitMapLifecycleConstants.maxActiveMaps(requestedPoolSize: 99), 4)
        XCTAssertEqual(GeoKitMapLifecycleConstants.maxActiveMaps(requestedPoolSize: 1), 1)
    }
}
