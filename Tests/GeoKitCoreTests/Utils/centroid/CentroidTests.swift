import GeoKitCore
import XCTest

final class CentroidTests: XCTestCase {
    func testPolygonCentroidMatchesFixture() throws {
        let fixture = try ParityFixtures.load().turf.centroid.polygon
        let centroid = Centroid.polygonCentroid(fixture.polygon.polygon)

        XCTAssertNotNil(centroid)
        XCTAssertEqual(centroid!.latitude, fixture.expected.latitude, accuracy: fixture.tolerance)
        XCTAssertEqual(centroid!.longitude, fixture.expected.longitude, accuracy: fixture.tolerance)
    }

    func testPointsCentroidMatchesFixture() throws {
        let fixture = try ParityFixtures.load().turf.centroid.points
        let points = fixture.points.map(\.latLon)
        let centroid = Centroid.pointsCentroid(points)

        XCTAssertNotNil(centroid)
        XCTAssertEqual(centroid!.latitude, fixture.expected.latitude, accuracy: fixture.tolerance)
        XCTAssertEqual(centroid!.longitude, fixture.expected.longitude, accuracy: fixture.tolerance)
    }
}
