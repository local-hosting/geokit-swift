import XCTest
@testable import GeoKitContract

final class MapSnapshotSchedulingPolicyTests: XCTestCase {
    func testPeekIndicesAroundCenter() {
        let slots = MapSnapshotSchedulingPolicy.peekIndices(
            centerIndex: 2,
            cardCount: 6,
            peekRadius: 2
        )
        XCTAssertEqual(slots.map(\.index), [1, 3, 0, 4])
        XCTAssertEqual(slots.map(\.peekDistance), [1, 1, 2, 2])
        XCTAssertFalse(slots.contains { $0.force })
    }

    func testPeekIndicesForcesPreviousCenterOnSwipe() {
        let slots = MapSnapshotSchedulingPolicy.peekIndices(
            centerIndex: 3,
            cardCount: 6,
            peekRadius: 2,
            previousCenterIndex: 1
        )
        XCTAssertEqual(slots.first?.index, 1)
        XCTAssertEqual(slots.first?.force, true)
    }
}
