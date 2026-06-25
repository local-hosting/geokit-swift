import GeoKitCore
import XCTest

final class BufferTests: XCTestCase {
    func testBufferPointMatchesFixture() throws {
        let fixture = try ParityFixtures.load().turf.buffer.point1km
        let polygon = try Buffer.bufferPoint(
            fixture.point.latLon,
            radiusMeters: fixture.radiusMeters,
            steps: fixture.steps
        )

        XCTAssertEqual(polygon.coordinates.first?.count, fixture.expectedRingCount)
        let area = Area.polygonArea(polygon)
        XCTAssertEqual(area, fixture.expectedAreaM2, accuracy: fixture.areaToleranceM2)
    }
}
