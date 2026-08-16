import GeoKitCore
import XCTest

final class RandomPointTests: XCTestCase {
    private let center = LatLon(latitude: 40.7128, longitude: -74.006)

    func testRandomPointInCircleWithinRadius() {
        for _ in 0..<20 {
            let point = Bearing.randomPointInCircle(from: center, radiusMeters: 5000)
            let distance = Distance.haversineMeters(from: center, to: point)
            XCTAssertLessThanOrEqual(distance, 5001)
        }
    }
}
