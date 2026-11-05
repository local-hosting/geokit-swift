import GeoKitCore
import XCTest

final class BoundsGeoTests: XCTestCase {
    func testBboxToPolygonMatchesFixture() throws {
        let fixture = try ParityFixtures.load().turf.boundsGeo.bboxToPolygon
        let ring = BoundsGeo.bboxToPolygon(fixture.bounds)
        XCTAssertFalse(ring.isEmpty)
        XCTAssertEqual(ring[0].latitude, fixture.expectedFirstPoint.latitude, accuracy: 0.0001)
        XCTAssertEqual(ring[0].longitude, fixture.expectedFirstPoint.longitude, accuracy: 0.0001)
    }

    func testGeometryBoundsMatchesFixture() throws {
        let fixture = try ParityFixtures.load().turf.boundsGeo.geometryBounds
        let bounds = BoundsGeo.getBounds(from: .polygon(fixture.polygon.polygon))
        XCTAssertNotNil(bounds)
        zip(bounds!, fixture.expected).forEach { actual, expected in
            XCTAssertEqual(actual, expected, accuracy: 0.0001)
        }
    }

    func testGetCenterFromBoundsMatchesFixture() throws {
        let fixtures = try ParityFixtures.load()
        let center = BoundsGeo.getCenter(from: fixtures.bounds.centerFromBounds.bounds)
        XCTAssertNotNil(center)
        XCTAssertEqual(center!.latitude, fixtures.bounds.centerFromBounds.center.latitude, accuracy: 0.0001)
        XCTAssertEqual(center!.longitude, fixtures.bounds.centerFromBounds.center.longitude, accuracy: 0.0001)
    }

    func testGetCenterFromCoordinatesUsesTurfBBoxCenter() throws {
        let fixtures = try ParityFixtures.load()
        let points = fixtures.bounds.nycPair.points.map(\.latLon)
        guard let bounds = BoundsCalculator.fromCoordinates(points) else {
            XCTFail("expected bounds")
            return
        }
        let fromCoords = BoundsGeo.getCenter(from: points)
        let fromBounds = BoundsGeo.getCenter(from: bounds)
        XCTAssertNotNil(fromCoords)
        XCTAssertNotNil(fromBounds)
        XCTAssertEqual(fromCoords!.latitude, fromBounds!.latitude, accuracy: 0.0001)
        XCTAssertEqual(fromCoords!.longitude, fromBounds!.longitude, accuracy: 0.0001)
    }
}
