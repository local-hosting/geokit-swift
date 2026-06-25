import GeoKitCore
import XCTest

final class GeoJSONTests: XCTestCase {
    func testGetCoordinatesMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let feature = fixtures.geojson.sampleFeature()
        XCTAssertEqual(GeoJSONHelpers.getCoordinates(from: feature), fixtures.geojson.pointCoordinates)
    }

    func testGetFeatureIdMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let feature = fixtures.geojson.sampleFeature()
        XCTAssertEqual(GeoJSONHelpers.getFeatureId(from: feature), fixtures.geojson.expectedFeatureId)
    }

    func testValidationMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let point = GeoJSONPoint(coordinates: fixtures.geojson.pointCoordinates)
        XCTAssertTrue(GeoJSONValidation.isValidPoint(point))
        XCTAssertTrue(GeoJSONValidation.validate(fixtures.geojson.sampleFeature()).valid)
    }

    func testRepairClosesPolygonRing() throws {
        let fixtures = try ParityFixtures.load()
        let open = GeoJSONGeometry.polygon(GeoJSONPolygon(coordinates: [fixtures.geojson.openRingCoordinates]))
        let repaired = GeoJSONRepair.repairGeometry(open)
        guard case .polygon(let polygon) = repaired else {
            return XCTFail("Expected repaired polygon")
        }
        let ring = polygon.coordinates[0]
        XCTAssertEqual(ring.first?[0], ring.last?[0])
        XCTAssertEqual(ring.first?[1], ring.last?[1])
        XCTAssertEqual(ring.count, fixtures.geojson.expectedClosedRingCount)
    }
}
