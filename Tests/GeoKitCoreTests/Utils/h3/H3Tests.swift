import GeoKitCore
import XCTest

final class H3Tests: XCTestCase {
    func testCoordinatesToCellMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.h3["nycRes9"]!
        let coordinate = LatLon(latitude: fixture.latitude, longitude: fixture.longitude)
        let cell = try H3.coordinatesToCell(coordinate, resolution: fixture.resolution)
        XCTAssertEqual(cell, fixture.expectedCell)
    }

    func testCellRoundTripPreservesCellID() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.h3["nycRes9"]!
        let coordinate = LatLon(latitude: fixture.latitude, longitude: fixture.longitude)
        let cell = try H3.coordinatesToCell(coordinate, resolution: fixture.resolution)
        let restored = try H3.cellToCoordinates(cell)
        let roundTrippedCell = try H3.coordinatesToCell(restored, resolution: fixture.resolution)
        XCTAssertEqual(roundTrippedCell, cell)
        XCTAssertEqual(try H3.resolution(of: cell), fixture.resolution)
    }
}
