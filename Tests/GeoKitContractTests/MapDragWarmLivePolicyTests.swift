import GeoKitContract
import XCTest

final class MapDragWarmLivePolicyTests: XCTestCase {
    func testForwardDragTargetsIndexOne() {
        let threshold = MapDragWarmLivePolicy.dragThreshold(containerWidth: 400)
        XCTAssertEqual(
            MapDragWarmLivePolicy.stackWarmTargetIndex(cardCount: 6, dragOffset: -threshold - 1, threshold: threshold),
            1
        )
        XCTAssertEqual(
            MapDragWarmLivePolicy.warmTargetIndex(
                layout: .stack,
                cardCount: 6,
                centerIndex: 0,
                dragOffset: -threshold - 1,
                threshold: threshold
            ),
            1
        )
    }

    func testBackwardDragTargetsBackCard() {
        let threshold = MapDragWarmLivePolicy.dragThreshold(containerWidth: 400)
        XCTAssertEqual(
            MapDragWarmLivePolicy.stackWarmTargetIndex(cardCount: 6, dragOffset: threshold + 1, threshold: threshold),
            5
        )
    }

    func testDeckForwardDragTargetsNextIndex() {
        let threshold = MapDragWarmLivePolicy.dragThreshold(containerWidth: 400)
        XCTAssertEqual(
            MapDragWarmLivePolicy.warmTargetIndex(
                layout: .deck,
                cardCount: 6,
                centerIndex: 2,
                dragOffset: -threshold - 1,
                threshold: threshold
            ),
            3
        )
    }

    func testDeckBackwardDragTargetsPreviousIndex() {
        let threshold = MapDragWarmLivePolicy.dragThreshold(containerWidth: 400)
        XCTAssertEqual(
            MapDragWarmLivePolicy.warmTargetIndex(
                layout: .deck,
                cardCount: 6,
                centerIndex: 2,
                dragOffset: threshold + 1,
                threshold: threshold
            ),
            1
        )
    }

    func testScrollLayoutDoesNotWarmOnDrag() {
        let threshold = MapDragWarmLivePolicy.dragThreshold(containerWidth: 400)
        XCTAssertNil(
            MapDragWarmLivePolicy.warmTargetIndex(
                layout: .scroll,
                cardCount: 6,
                centerIndex: 2,
                dragOffset: -threshold - 1,
                threshold: threshold
            )
        )
    }

    func testSmallDragDoesNotWarm() {
        let threshold = MapDragWarmLivePolicy.dragThreshold(containerWidth: 400)
        XCTAssertNil(
            MapDragWarmLivePolicy.stackWarmTargetIndex(cardCount: 6, dragOffset: 10, threshold: threshold)
        )
    }

    func testWarmTargetEnablesLiveDataOnFanSlot() {
        XCTAssertTrue(
            MapCardMediaPresentationPolicy.isLiveDataEnabled(
                liveCardID: "center",
                warmLiveCardID: "next",
                cardID: "next",
                allowsLiveMount: false
            )
        )
    }
}
