import GeoKitCore
import XCTest

final class H3Tests: XCTestCase {
    func testCoordinatesToCellMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.h3.nycRes9
        let coordinate = LatLon(latitude: fixture.latitude, longitude: fixture.longitude)
        let cell = try H3.coordinatesToCell(coordinate, resolution: fixture.resolution)
        XCTAssertEqual(cell, fixture.expectedCell)
    }

    func testCellRoundTripPreservesCellID() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.h3.nycRes9
        let coordinate = LatLon(latitude: fixture.latitude, longitude: fixture.longitude)
        let cell = try H3.coordinatesToCell(coordinate, resolution: fixture.resolution)
        let restored = try H3.cellToCoordinates(cell)
        let roundTrippedCell = try H3.coordinatesToCell(restored, resolution: fixture.resolution)
        XCTAssertEqual(roundTrippedCell, cell)
        XCTAssertEqual(try H3.resolution(of: cell), fixture.resolution)
    }

    func testParentMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.h3.parentRes8
        let parent = try H3.parent(of: fixture.cell, resolution: fixture.resolution)
        XCTAssertEqual(parent, fixture.expectedParent)
        XCTAssertEqual(try H3.resolution(of: parent), fixture.resolution)
    }

    func testChildrenCountMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.h3.childrenRes10
        let children = try H3.children(of: fixture.cell, resolution: fixture.resolution)
        XCTAssertEqual(children.count, fixture.expectedChildCount)
    }

    func testNeighborsDiskMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.h3.neighborsK1
        let neighbors = try H3.neighbors(of: fixture.cell, k: fixture.k)
        XCTAssertEqual(neighbors.count, fixture.expectedCount)
        XCTAssertEqual(neighbors.contains(fixture.cell), fixture.containsCenter)
        if let ringNeighbor = neighbors.first(where: { $0 != fixture.cell }) {
            XCTAssertEqual(try H3.areNeighbors(fixture.cell, ringNeighbor), fixture.ringNeighborAreNeighbors)
        }
    }

    func testMetricsMatchNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.h3.metricsRes9
        let edgeLength = try H3.edgeLength(resolution: fixture.resolution)
        let cellArea = try H3.cellArea(resolution: fixture.resolution)
        XCTAssertEqual(edgeLength, fixture.expectedEdgeLengthMeters, accuracy: fixture.edgeLengthToleranceMeters)
        XCTAssertEqual(cellArea, fixture.expectedCellAreaM2, accuracy: fixture.cellAreaToleranceM2)
    }
}
