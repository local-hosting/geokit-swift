import GeoKitContract
import XCTest

final class MapOfflineContextLoaderPolicyTests: XCTestCase {
    func testDefaultZoomRangeClampsToBudget() {
        let zoom = MapOfflinePolicyResolver.defaultZoomRange(for: 16, platform: .web)
        XCTAssertLessThanOrEqual(zoom.maxZoom, MapOfflineDefaults.webStorageBudget.maxPrefetchZoom)
        XCTAssertLessThanOrEqual(zoom.minZoom, zoom.maxZoom)
    }

    func testBoundsFromPinsAddsPadding() throws {
        let pins = [
            MapPin(id: UUID(), latitude: 40.0, longitude: -74.0, pinHeading: "a", pinSubheading: "", icon: "", isPrimary: false),
            MapPin(id: UUID(), latitude: 41.0, longitude: -73.0, pinHeading: "b", pinSubheading: "", icon: "", isPrimary: false),
        ]
        let bounds = try XCTUnwrap(MapOfflinePolicyResolver.boundsFromPins(pins, padding: 0.1))
        XCTAssertEqual(bounds.south, 39.9, accuracy: 0.0001)
        XCTAssertEqual(bounds.north, 41.1, accuracy: 0.0001)
    }
}
