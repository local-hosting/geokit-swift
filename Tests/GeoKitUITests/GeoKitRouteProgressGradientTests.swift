import GeoKitUI
import XCTest

final class GeoKitRouteProgressGradientTests: XCTestCase {
    func testExpressionMatchesNodeShape() {
        let expression = GeoKitRouteProgressGradient.expression(
            options: GeoKitRouteProgressGradientOptions(color: "#6942F8", progress: 0.42)
        )

        XCTAssertEqual(expression[0] as? String, "step")
        XCTAssertEqual(expression[2] as? String, "rgba(105, 66, 248, 0.55)")
        XCTAssertEqual(expression[3] as? Double ?? 0, 0.415, accuracy: 0.001)
        XCTAssertEqual(expression[4] as? String, "rgba(105, 66, 248, 0.35)")
    }
}
