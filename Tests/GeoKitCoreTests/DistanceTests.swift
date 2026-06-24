import GeoKitCore
import XCTest

final class DistanceTests: XCTestCase {
    func testNycToLaWithinExpectedRange() throws {
        let fixtures = try ParityFixtures.load()
        let caseFixture = fixtures.distance.nycToLaMeters
        let from = fixtures.coordinate(named: caseFixture.from)
        let to = fixtures.coordinate(named: caseFixture.to)
        let meters = Distance.haversineMeters(from: from, to: to)
        XCTAssertGreaterThan(meters, caseFixture.minMeters)
        XCTAssertLessThan(meters, caseFixture.maxMeters)
    }

    func testSamePointIsZero() throws {
        let fixtures = try ParityFixtures.load()
        let caseFixture = fixtures.distance.samePointMeters
        let point = fixtures.coordinate(named: caseFixture.from)
        XCTAssertEqual(Distance.haversineMeters(from: point, to: point), caseFixture.expectedMeters)
    }

    func testWithinDistanceThreshold() throws {
        let fixtures = try ParityFixtures.load()
        let caseFixture = fixtures.distance.nearbyWithin1km
        let from = fixtures.coordinate(named: caseFixture.from)
        let to = fixtures.coordinate(named: caseFixture.to)
        let within = Distance.withinDistance(caseFixture.thresholdMeters, from: from, to: to)
        XCTAssertEqual(within, caseFixture.expectedWithin)
    }
}
