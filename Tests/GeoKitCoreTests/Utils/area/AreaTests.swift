import GeoKitCore
import XCTest

final class AreaTests: XCTestCase {
    func testPolygonAreaMatchesFixture() throws {
        let fixture = try ParityFixtures.load().turf.area.polygonM2
        let area = Area.polygonArea(fixture.polygon.polygon)
        XCTAssertEqual(area, fixture.expectedM2, accuracy: fixture.toleranceM2)
    }

    func testBoundsAreaMatchesFixture() throws {
        let fixture = try ParityFixtures.load().turf.area.boundsM2
        let area = Area.boundsArea(fixture.bounds)
        XCTAssertEqual(area, fixture.expectedM2, accuracy: fixture.toleranceM2)
    }
}
