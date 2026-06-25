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
}
