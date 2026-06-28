import CoreGraphics
import GeoKitContract
import XCTest

final class MapSnapshotDisplayPolicyTests: XCTestCase {
    func testDownscaleOnlyFillScaleNeverExceedsOne() {
        let snapshot = CGSize(width: 400, height: 800)
        let largerSlot = CGSize(width: 800, height: 1600)
        XCTAssertEqual(
            MapSnapshotDisplayPolicy.downscaleOnlyFillScale(
                snapshotPointSize: snapshot,
                slotSize: largerSlot
            ),
            1,
            accuracy: 0.001
        )
    }

    func testDownscaleOnlyFillScaleShrinksForSmallerSlot() {
        let snapshot = CGSize(width: 400, height: 800)
        let slot = CGSize(width: 200, height: 400)
        XCTAssertEqual(
            MapSnapshotDisplayPolicy.downscaleOnlyFillScale(
                snapshotPointSize: snapshot,
                slotSize: slot
            ),
            0.5,
            accuracy: 0.001
        )
    }

    func testDownscaleOnlyFillSizeMatchesScaledDimensions() {
        let snapshot = CGSize(width: 390, height: 844)
        let slot = CGSize(width: 195, height: 422)
        let draw = MapSnapshotDisplayPolicy.downscaleOnlyFillSize(
            snapshotPointSize: snapshot,
            slotSize: slot
        )
        XCTAssertEqual(draw.width, 195, accuracy: 0.001)
        XCTAssertEqual(draw.height, 422, accuracy: 0.001)
    }
}
