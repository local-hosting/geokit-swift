import GeoKitContract
import GeoKitUI
import XCTest

@MainActor
final class MapOfflineContextLoaderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MapOfflineContextLoader.resetForTesting()
        GeoKitRuntime.resetForTesting()
    }

    func testInvokesHostHookOnContextLoad() {
        let expectation = expectation(description: "prefetch hook")
        GeoKitRuntime.prefetchOfflineRegionOnContextLoad = { prefetch, _ in
            XCTAssertEqual(prefetch.mapId, "card-1")
            expectation.fulfill()
        }

        let request = MapContentRequest(
            id: "card-1",
            phase: .live,
            isExpanded: true,
            mapStyleURI: "mapbox://styles/mapbox/standard",
            preferredZoom: 12,
            mapProviderId: .mapbox,
            offlineContext: MapOfflineContextLoad(
                bounds: MapOfflineBounds(south: 40.7, west: -74.02, north: 40.72, east: -74.0)
            )
        )
        MapOfflineContextLoader.loadIfNeeded(for: request)
        wait(for: [expectation], timeout: 1)
    }

    func testSkipsDuplicatePrefetchForSameBounds() {
        var callCount = 0
        GeoKitRuntime.prefetchOfflineRegionOnContextLoad = { _, _ in callCount += 1 }
        let request = MapContentRequest(
            id: "card-2",
            phase: .live,
            isExpanded: true,
            mapProviderId: .mapbox,
            offlineContext: MapOfflineContextLoad(
                bounds: MapOfflineBounds(south: 40.7, west: -74.02, north: 40.72, east: -74.0)
            )
        )
        MapOfflineContextLoader.loadIfNeeded(for: request)
        MapOfflineContextLoader.loadIfNeeded(for: request)
        XCTAssertEqual(callCount, 1)
    }
}
