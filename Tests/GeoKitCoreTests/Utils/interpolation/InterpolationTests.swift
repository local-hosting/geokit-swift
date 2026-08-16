import GeoKitCore
import XCTest

final class InterpolationTests: XCTestCase {
    private let path: [LatLon] = [
        LatLon(latitude: 40.7128, longitude: -74.006),
        LatLon(latitude: 40.72, longitude: -74.0),
        LatLon(latitude: 40.73, longitude: -73.99),
    ]

    func testAlongPathStartAndEnd() {
        let start = Interpolation.alongPath(fraction: 0, coordinates: path)
        XCTAssertEqual(start?.latitude ?? 0, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(start?.longitude ?? 0, -74.006, accuracy: 0.0001)

        let end = Interpolation.alongPath(fraction: 1, coordinates: path)
        XCTAssertEqual(end?.latitude ?? 0, 40.73, accuracy: 0.0001)
        XCTAssertEqual(end?.longitude ?? 0, -73.99, accuracy: 0.0001)
    }

    func testAlongPathMidpoint() {
        let midpoint = Interpolation.alongPath(fraction: 0.5, coordinates: path)
        XCTAssertNotNil(midpoint)
        XCTAssertGreaterThan(midpoint!.latitude, 40.7128)
        XCTAssertLessThan(midpoint!.latitude, 40.73)
    }

    func testAlongPathAcceptsGeoJSONPositions() {
        let geoJsonPath: [(Double, Double)] = [
            (-74.006, 40.7128),
            (-74.0, 40.72),
            (-73.99, 40.73),
        ]
        let end = Interpolation.alongPath(fraction: 1, positions: geoJsonPath)
        XCTAssertEqual(end?.latitude ?? 0, 40.73, accuracy: 0.0001)
        XCTAssertEqual(end?.longitude ?? 0, -73.99, accuracy: 0.0001)
    }
}
