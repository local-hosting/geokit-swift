import GeoKitCore
import XCTest

final class LengthTests: XCTestCase {
    func testLineLengthMatchesFixture() throws {
        let fixture = try ParityFixtures.load().turf.length.lineMeters
        let coordinates = fixture.coordinates.map(\.latLon)
        let length = Length.lineLengthMeters(coordinates)
        XCTAssertEqual(length, fixture.expectedMeters, accuracy: fixture.toleranceMeters)
    }

    func testPerimeterMatchesFixture() throws {
        let fixture = try ParityFixtures.load().turf.length.perimeterMeters
        let perimeter = Length.perimeterMeters(fixture.polygon.polygon)
        XCTAssertEqual(perimeter, fixture.expectedMeters, accuracy: fixture.toleranceMeters)
    }
}
