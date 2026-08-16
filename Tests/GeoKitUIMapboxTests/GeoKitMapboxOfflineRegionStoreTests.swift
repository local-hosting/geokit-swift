#if os(iOS) || os(visionOS)
import GeoKitContract
import GeoKitUIMapbox
import MapboxMaps
import XCTest

@MainActor
final class GeoKitMapboxOfflineRegionStoreTests: XCTestCase {
    func testMakeLoadOptionsForBounds() throws {
        let request = MapOfflinePrefetchRequest(
            mapId: "trip-1",
            bounds: MapOfflineBounds(south: 40.7, west: -74.02, north: 40.72, east: -74.0),
            zoomRange: MapOfflineZoomRange(minZoom: 10, maxZoom: 12)
        )
        let normalized = try MapOfflinePolicyResolver.validate(request: request, platform: .nativeMapbox)
        let offlineManager = OfflineManager()
        let options = GeoKitMapboxOfflineRegionStore.makeLoadOptions(
            request: normalized,
            styleURI: .standard,
            offlineManager: offlineManager
        )
        XCTAssertNotNil(options)
        XCTAssertEqual(options?.descriptors.count, 1)
    }
}
#endif
