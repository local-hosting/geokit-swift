import GeoKitCore
import XCTest

final class BoundsTests: XCTestCase {
    func testBoundsFromCoordinatesMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let points = fixtures.bounds.nycPair.points.map(\.latLon)
        let bounds = BoundsCalculator.fromCoordinates(points)
        XCTAssertEqual(bounds, fixtures.bounds.nycPair.expected)
    }

    func testCenterFromBoundsMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let center = BoundsCalculator.center(of: fixtures.bounds.centerFromBounds.bounds)
        XCTAssertNotNil(center)
        XCTAssertEqual(center!.latitude, fixtures.bounds.centerFromBounds.center.latitude, accuracy: 0.0001)
        XCTAssertEqual(center!.longitude, fixtures.bounds.centerFromBounds.center.longitude, accuracy: 0.0001)
    }

    func testCenterAndZoomMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let result = BoundsCalculator.centerAndZoom(from: fixtures.bounds.centerAndZoom.bounds)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.latitude, fixtures.bounds.centerAndZoom.expected.latitude, accuracy: 0.05)
        XCTAssertEqual(result!.longitude, fixtures.bounds.centerAndZoom.expected.longitude, accuracy: 0.05)
        XCTAssertEqual(result!.zoom, fixtures.bounds.centerAndZoom.expected.zoom)
    }

    func testFitViewportReturnsCenterAndZoom() {
        let nyc = LatLon(latitude: 40.7128, longitude: -74.006)
        let la = LatLon(latitude: 34.0522, longitude: -118.2437)
        let fit = BoundsCalculator.fitViewport(
            coordinates: [nyc, la],
            mapSize: MapSize(width: 390, height: 844)
        )
        XCTAssertNotNil(fit)
        XCTAssertTrue((fit!.zoom >= 0) && (fit!.zoom <= 22))
    }
}
