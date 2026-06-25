import GeoKitContract
import XCTest

/// Mirrors GeoKitTestApp card wiring — collapsed cards must request snapshot phase with pins.
final class HostMapRequestTests: XCTestCase {
    private let nycPin = MapPin(
        id: UUID(uuidString: "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1")!,
        latitude: 40.7128,
        longitude: -74.006,
        pinHeading: "City Hall",
        pinSubheading: "NYC",
        icon: "building.2",
        isPrimary: false
    )

    func testCollapsedCenterHostCardUsesLivePhaseWhenSurfaceReady() {
        let request = hostMapRequest(isExpanded: false, isTopCard: true, provider: .apple)
        XCTAssertEqual(request.phase, .live)
        XCTAssertFalse(request.pins.isEmpty)
        XCTAssertEqual(request.mapProviderId, .apple)
        XCTAssertEqual(request.snapshotPriority, .top)
    }

    func testCollapsedPeekHostCardUsesSnapshotWhenCached() {
        let request = MapContentRequestBuilder.make(
            id: "nyc",
            policy: MapStagePolicy(stage: .peek, isExpanded: false),
            lifecycle: MapLifecycleState(hasSnapshot: true, isStyleReady: false, isSurfaceReady: true),
            isExpanded: false,
            pins: [nycPin],
            mapProviderId: .apple
        )
        XCTAssertEqual(request.phase, .snapshot)
    }

    func testExpandedHostCardUsesLivePhase() {
        let request = hostMapRequest(isExpanded: true, isTopCard: true, provider: .mapbox)
        XCTAssertEqual(request.phase, .live)
        XCTAssertTrue(request.mapAcceptsUserInteraction)
    }

    func testBackgroundCardUsesBackgroundSnapshotPriority() {
        let request = hostMapRequest(isExpanded: false, isTopCard: false, provider: .apple)
        XCTAssertEqual(request.snapshotPriority, .background)
    }

    func testLifecycleSurfaceNotReadyNeverProducesLiveRequest() {
        let request = MapContentRequestBuilder.make(
            id: "nyc",
            policy: MapStagePolicy(stage: .expand, isExpanded: true),
            lifecycle: MapLifecycleState(hasSnapshot: true, isStyleReady: true, isSurfaceReady: false),
            isExpanded: true,
            pins: [nycPin],
            mapProviderId: .apple
        )
        XCTAssertEqual(request.phase, .placeholder)
    }

    private func hostMapRequest(
        isExpanded: Bool,
        isTopCard: Bool,
        provider: MapProviderId
    ) -> MapContentRequest {
        let policy: MapStagePolicy
        if isExpanded {
            policy = MapStagePolicy(stage: .expand, isExpanded: true)
        } else if isTopCard {
            policy = MapStagePolicy(stage: .center, isExpanded: false)
        } else {
            policy = MapStagePolicy(stage: .peek, isExpanded: false)
        }
        return MapContentRequestBuilder.make(
            id: "nyc",
            policy: policy,
            lifecycle: MapLifecycleState(
                hasSnapshot: !isTopCard,
                isStyleReady: true,
                isSurfaceReady: true
            ),
            isExpanded: isExpanded,
            title: "New York",
            mapStyleURI: "mapbox://styles/mapbox/standard",
            preferredZoom: 12,
            pins: [nycPin],
            showUserPuck: false,
            mapProviderId: provider,
            snapshotPriority: isTopCard ? .top : .background
        )
    }
}
