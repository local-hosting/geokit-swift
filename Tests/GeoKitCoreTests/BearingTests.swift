import GeoKitCore
import XCTest

final class BearingTests: XCTestCase {
    func testCardinalBearingsMatchFixtures() throws {
        let fixtures = try ParityFixtures.load()
        for (_, fixture) in fixtures.bearing {
            let value = Bearing.initial(from: fixture.from.latLon, to: fixture.to.latLon)
            XCTAssertEqual(value, fixture.expectedDegrees, accuracy: fixture.toleranceDegrees)
        }
    }
}
