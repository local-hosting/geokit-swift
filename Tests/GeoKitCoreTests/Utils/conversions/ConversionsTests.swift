import GeoKitCore
import XCTest

final class ConversionsTests: XCTestCase {
    func testDMSMatchesFixtures() throws {
        let fixtures = try ParityFixtures.load().turf.conversions

        for fixture in [fixtures.nycLatitudeDms, fixtures.nycLongitudeDms] {
            let dms = Conversions.toDMS(fixture.decimal, isLongitude: fixture.isLongitude)
            XCTAssertEqual(dms.degrees, fixture.expected.degrees)
            XCTAssertEqual(dms.minutes, fixture.expected.minutes)
            XCTAssertEqual(dms.seconds, fixture.expected.seconds, accuracy: 0.01)
            XCTAssertEqual(dms.direction.rawValue, fixture.expected.direction)
        }
    }

    func testFromDMSRoundTrip() throws {
        let fixtures = try ParityFixtures.load().turf.conversions
        let latitudeDms = Conversions.toDMS(fixtures.nycLatitudeDms.decimal, isLongitude: false)
        let longitudeDms = Conversions.toDMS(fixtures.nycLongitudeDms.decimal, isLongitude: true)
        XCTAssertEqual(Conversions.fromDMS(latitudeDms), fixtures.nycLatitudeDms.decimal, accuracy: 0.0001)
        XCTAssertEqual(Conversions.fromDMS(longitudeDms), fixtures.nycLongitudeDms.decimal, accuracy: 0.0001)
    }
}
