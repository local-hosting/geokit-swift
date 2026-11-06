import GeoKitContract
import XCTest

final class OfflinePolicyParityTests: XCTestCase {
    func testDefaultsMatchFixture() throws {
        let defaults = try ParityFixtures.load().offline.defaults
        XCTAssertEqual(MapOfflineDefaults.webStorageBudget.maxPrefetchZoom, defaults.webMaxPrefetchZoom)
        XCTAssertEqual(MapOfflineDefaults.webStorageBudget.maxTileCount, defaults.webMaxTileCount)
        XCTAssertEqual(
            MapOfflineDefaults.nativeMapboxStorageBudget.maxPrefetchZoom,
            defaults.nativeMapboxMaxPrefetchZoom
        )
        XCTAssertEqual(
            MapOfflineDefaults.liveMapCoverageThreshold,
            defaults.liveMapCoverageThreshold,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            MapOfflineDefaults.snapshotFallbackCoverageThreshold,
            defaults.snapshotFallbackCoverageThreshold,
            accuracy: 0.0001
        )
    }

    func testWebZoomClampMatchesFixture() throws {
        let clamp = try ParityFixtures.load().offline.webZoomClamp
        let normalized = try MapOfflinePolicyResolver.validate(
            request: MapOfflinePrefetchRequest(
                mapId: "card-1",
                bounds: clamp.bounds.bounds,
                zoomRange: MapOfflineZoomRange(minZoom: clamp.inputMinZoom, maxZoom: clamp.inputMaxZoom)
            ),
            platform: .web
        )
        XCTAssertEqual(normalized.zoomRange.maxZoom, clamp.expectedMaxZoom)
    }

    func testTileCountMatchesFixture() throws {
        let tileCount = try ParityFixtures.load().offline.tileCount
        let bounds = tileCount.bounds.bounds
        let zoom = MapOfflineZoomRange(minZoom: tileCount.minZoom, maxZoom: tileCount.maxZoom)
        let estimated = MapOfflinePolicyResolver.estimateTileCount(bounds: bounds, zoomRange: zoom)
        let enumerated = MapOfflinePolicyResolver.enumerateTileCoordinates(bounds: bounds, zoomRange: zoom)
        XCTAssertEqual(estimated, tileCount.expected)
        XCTAssertEqual(enumerated.count, tileCount.enumerated)
    }

    func testCoverageMatchesFixture() throws {
        let offline = try ParityFixtures.load().offline
        for fixture in [offline.sparseCoverage, offline.liveCoverage] {
            let policy = try XCTUnwrap(MapOfflinePolicy(rawValue: fixture.policy))
            let coverage = MapOfflinePolicyResolver.coverage(
                tilesCached: fixture.tilesCached,
                tilesRequired: fixture.tilesRequired,
                policy: policy
            )
            XCTAssertEqual(coverage.recommendsLiveMap, fixture.recommendsLiveMap)
            XCTAssertEqual(coverage.recommendsSnapshotFallback, fixture.recommendsSnapshotFallback)
            XCTAssertEqual(coverage.status.rawValue, fixture.status)
        }
    }

    func testOversizedPrefetchMatchesFixture() throws {
        let oversized = try ParityFixtures.load().offline.oversizedPrefetch
        let request = MapOfflinePrefetchRequest(
            mapId: "card-1",
            bounds: oversized.bounds.bounds,
            zoomRange: MapOfflineZoomRange(minZoom: oversized.minZoom, maxZoom: oversized.maxZoom),
            budget: MapOfflineStorageBudget(
                maxBytes: 100_000_000,
                maxPrefetchZoom: 15,
                maxTileCount: oversized.maxTileCount
            )
        )
        XCTAssertThrowsError(try MapOfflinePolicyResolver.validate(request: request, platform: .web)) { error in
            guard case MapOfflinePolicyError.estimatedTileCountExceedsBudget = error else {
                return XCTFail("expected \(oversized.expectedError), got \(error)")
            }
        }
        XCTAssertEqual(oversized.expectedError, "estimatedTileCountExceedsBudget")
    }
}
