import GeoKitCore
import XCTest

final class EasingTests: XCTestCase {
    func testEaseInOutCubicEndpoints() {
        XCTAssertEqual(Easing.easeInOutCubic(0), 0)
        XCTAssertEqual(Easing.easeInOutCubic(1), 1)
        XCTAssertEqual(Easing.easeInOutCubic(0.5), 0.5, accuracy: 0.0001)
    }

    func testEaseLinearClamps() {
        XCTAssertEqual(Easing.easeLinear(-1), 0)
        XCTAssertEqual(Easing.easeLinear(2), 1)
        XCTAssertEqual(Easing.easeLinear(0.25), 0.25)
    }
}
