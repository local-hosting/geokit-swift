import GeoKitCore
import XCTest

final class ContainmentTests: XCTestCase {
    func testPointInPolygonMatchesFixtures() throws {
        let fixtures = try ParityFixtures.load().turf.containment

        XCTAssertTrue(
            Containment.isPointInPolygon(
                fixtures.pointInside.point.latLon,
                polygon: fixtures.pointInside.polygon.polygon
            )
        )
        XCTAssertEqual(
            Containment.isPointInPolygon(
                fixtures.pointInside.point.latLon,
                polygon: fixtures.pointInside.polygon.polygon
            ),
            fixtures.pointInside.expected
        )
        XCTAssertEqual(
            Containment.isPointInPolygon(
                fixtures.pointOutside.point.latLon,
                polygon: fixtures.pointOutside.polygon.polygon
            ),
            fixtures.pointOutside.expected
        )
    }

    func testBoundsContainmentMatchesFixtures() throws {
        let fixtures = try ParityFixtures.load().turf.containment

        XCTAssertEqual(
            Containment.isPointInBounds(
                fixtures.boundsContainsPoint.point.latLon,
                bounds: fixtures.boundsContainsPoint.bounds
            ),
            fixtures.boundsContainsPoint.expected
        )
        XCTAssertEqual(
            Containment.isBoundsContained(
                outer: fixtures.boundsContainsBounds.outer,
                inner: fixtures.boundsContainsBounds.inner
            ),
            fixtures.boundsContainsBounds.expected
        )
        XCTAssertEqual(
            Containment.doBoundsIntersect(
                fixtures.boundsIntersects.bounds1,
                fixtures.boundsIntersects.bounds2
            ),
            fixtures.boundsIntersects.expected
        )
    }
}
