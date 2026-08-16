import GeoKitContract
import XCTest

final class MapOfflinePolicyTests: XCTestCase {
    func testEnumerateMatchesEstimate() {
        let bounds = MapOfflineBounds(south: 40.7, west: -74.1, north: 40.8, east: -73.9)
        let zoomRange = MapOfflineZoomRange(minZoom: 10, maxZoom: 11)
        let tiles = MapOfflinePolicyResolver.enumerateTileCoordinates(bounds: bounds, zoomRange: zoomRange)
        XCTAssertEqual(tiles.count, MapOfflinePolicyResolver.estimateTileCount(bounds: bounds, zoomRange: zoomRange))
    }

    func testValidatePrefetchClampsWebZoom() throws {
        let request = MapOfflinePrefetchRequest(
            mapId: "card-1",
            bounds: MapOfflineBounds(south: 40.7, west: -74.1, north: 40.8, east: -73.9),
            zoomRange: MapOfflineZoomRange(minZoom: 10, maxZoom: 20)
        )
        let normalized = try MapOfflinePolicyResolver.validate(request: request, platform: .web)
        XCTAssertEqual(normalized.zoomRange.maxZoom, MapOfflineDefaults.webStorageBudget.maxPrefetchZoom)
    }

    func testCoverageRecommendsSnapshotWhenSparse() {
        let coverage = MapOfflinePolicyResolver.coverage(
            tilesCached: 10,
            tilesRequired: 100,
            policy: .snapshotFallback
        )
        XCTAssertEqual(coverage.status, .idle)
        XCTAssertTrue(coverage.recommendsSnapshotFallback)
        XCTAssertFalse(coverage.recommendsLiveMap)
    }

    func testCoverageRecommendsLiveWhenMostlyCached() {
        let coverage = MapOfflinePolicyResolver.coverage(
            tilesCached: 85,
            tilesRequired: 100,
            policy: .cacheFirst
        )
        XCTAssertEqual(coverage.status, .partial)
        XCTAssertTrue(coverage.recommendsLiveMap)
    }

    func testRejectPrefetchWhenTileEstimateExceedsBudget() {
        let request = MapOfflinePrefetchRequest(
            mapId: "card-1",
            bounds: MapOfflineBounds(south: 40.7, west: -74.1, north: 40.8, east: -73.9),
            zoomRange: MapOfflineZoomRange(minZoom: 10, maxZoom: 12),
            budget: MapOfflineStorageBudget(maxBytes: 100_000_000, maxPrefetchZoom: 15, maxTileCount: 1)
        )
        XCTAssertThrowsError(try MapOfflinePolicyResolver.validate(request: request, platform: .web)) { error in
            guard case MapOfflinePolicyError.estimatedTileCountExceedsBudget = error else {
                return XCTFail("expected estimatedTileCountExceedsBudget, got \(error)")
            }
        }
    }
}
