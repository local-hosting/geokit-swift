import GeoKitCore
import XCTest

final class BearingTests: XCTestCase {
    func testCardinalBearingsMatchFixtures() throws {
        let fixtures = try ParityFixtures.load()
        for key in ["east", "north"] {
            let fixture = key == "east" ? fixtures.bearing.east : fixtures.bearing.north
            let value = Bearing.initial(from: fixture.from.latLon, to: fixture.to.latLon)
            XCTAssertEqual(value, fixture.expectedDegrees, accuracy: fixture.toleranceDegrees)
        }
    }

    func testMidpointMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.bearing.midpointNycLa
        let midpoint = Bearing.midpoint(
            from: fixtures.coordinate(named: fixture.from),
            to: fixtures.coordinate(named: fixture.to)
        )
        XCTAssertEqual(midpoint.latitude, fixture.expected.latitude, accuracy: fixture.toleranceDegrees)
        XCTAssertEqual(midpoint.longitude, fixture.expected.longitude, accuracy: fixture.toleranceDegrees)
    }

    func testDestinationMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.bearing.destination1kmEast
        let destination = Bearing.destinationMeters(
            from: fixtures.coordinate(named: fixture.from),
            distance: fixture.distanceMeters,
            bearingDegrees: fixture.bearingDegrees
        )
        XCTAssertEqual(destination.latitude, fixture.expected.latitude, accuracy: fixture.toleranceDegrees)
        XCTAssertEqual(destination.longitude, fixture.expected.longitude, accuracy: fixture.toleranceDegrees)
    }
}
