import GeoKitUI
import XCTest

final class GeoKitMapViewportSettledTests: XCTestCase {
    func testFiresAfterDragEnd() {
        let expectation = expectation(description: "settled")
        let coordinator = GeoKitMapViewportSettledCoordinator(onSettled: {
            expectation.fulfill()
        })

        coordinator.handleDragStart()
        coordinator.handleDragEnd()

        wait(for: [expectation], timeout: 1)
    }
}
