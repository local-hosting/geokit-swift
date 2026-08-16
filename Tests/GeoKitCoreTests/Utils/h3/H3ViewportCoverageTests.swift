import XCTest
@testable import GeoKitCore

final class H3ViewportCoverageTests: XCTestCase {
    func testNormalizeToResolutionRollsChildToParent() throws {
        let parent = try H3.coordinatesToCell(LatLon(latitude: 42.36, longitude: -71.06), resolution: 7)
        let child = try H3.coordinatesToCell(LatLon(latitude: 42.361, longitude: -71.061), resolution: 8)
        let normalized = try H3.normalizeToResolution(child, resolution: 7)
        XCTAssertEqual(normalized, parent)
    }

    func testFilterCellsInCoverage() throws {
        let res = 7
        let center = try H3.coordinatesToCell(LatLon(latitude: 42.36, longitude: -71.06), resolution: res)
        let child = try H3.coordinatesToCell(LatLon(latitude: 42.361, longitude: -71.061), resolution: res + 1)
        let filtered = try H3ViewportCoverage.filterCellsInCoverage([child, center], coverageIndex: [center], resolution: res)
        XCTAssertTrue(filtered.contains(center))
    }
}
