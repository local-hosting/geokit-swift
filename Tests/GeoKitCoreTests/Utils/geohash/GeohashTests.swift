import GeoKitCore
import XCTest

final class GeohashTests: XCTestCase {
    func testEncodeMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.geohash.encodeNycRes9
        let coordinate = fixtures.coordinate(named: "nyc")
        XCTAssertEqual(Geohash.encode(coordinate, precision: fixture.precision), fixture.expectedHash)
    }

    func testDecodeMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.geohash.decodeRes9
        let decoded = try Geohash.decode(fixture.hash)
        XCTAssertEqual(decoded.latitude, fixture.expected.latitude, accuracy: fixture.tolerance)
        XCTAssertEqual(decoded.longitude, fixture.expected.longitude, accuracy: fixture.tolerance)
    }

    func testBoundsMatchNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.geohash.boundsRes5
        let bounds = try Geohash.bounds(fixture.hash)
        XCTAssertEqual(bounds, fixture.expected)
    }

    func testNeighborsMatchNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.geohash.neighborsRes5
        let neighbors = try Geohash.neighbors(fixture.hash)
        XCTAssertEqual(neighbors.n, fixture.expected.n)
        XCTAssertEqual(neighbors.ne, fixture.expected.ne)
        XCTAssertEqual(neighbors.e, fixture.expected.e)
        XCTAssertEqual(neighbors.se, fixture.expected.se)
        XCTAssertEqual(neighbors.s, fixture.expected.s)
        XCTAssertEqual(neighbors.sw, fixture.expected.sw)
        XCTAssertEqual(neighbors.w, fixture.expected.w)
        XCTAssertEqual(neighbors.nw, fixture.expected.nw)
        XCTAssertEqual(try Geohash.neighborsArray(fixture.hash), fixture.expectedArray)
        XCTAssertEqual(try Geohash.neighbor(fixture.hash, direction: .north), fixture.expected.n)
    }

    func testValidationMatchesNodeFixture() throws {
        let fixtures = try ParityFixtures.load()
        let fixture = fixtures.geohash.validation
        XCTAssertEqual(Geohash.isValid(fixture.validHash), fixture.validExpected)
        XCTAssertEqual(Geohash.isValid(fixture.invalidHash), fixture.invalidExpected)
    }
}
