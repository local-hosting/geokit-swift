import GeoKitCore
import XCTest

final class CoordinatesTests: XCTestCase {
    func testValidationFixtures() throws {
        let fixtures = try ParityFixtures.load()
        for (_, fixture) in fixtures.validation {
            let coordinate = LatLon(latitude: fixture.latitude, longitude: fixture.longitude)
            XCTAssertEqual(Coordinates.isValid(coordinate), fixture.expected)
        }
    }

    func testLonLatRoundTrip() {
        let original = LatLon(latitude: 40.7128, longitude: -74.006)
        let lonLat = Coordinates.toLonLat(original)
        let restored = Coordinates.toLatLon(longitude: lonLat.longitude, latitude: lonLat.latitude)
        XCTAssertEqual(restored, original)
    }
}
