import XCTest

/// Regression: card switch must not leave the center-card media loading spinner stuck.
final class GeoKitDemoCardSwitchUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        app.launch()
    }

    func testAppLaunchesAndShowsRoot() throws {
        XCTAssertTrue(app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["New York"].waitForExistence(timeout: 10))
    }

    func testLaunchFrontCardClearsLoadingSpinner() throws {
        XCTAssertTrue(app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["New York"].waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForCenterMediaReady(timeout: 30),
            "Front card should clear the center loading overlay"
        )
    }

    func testSwitchToLouisvilleClearsLoadingSpinner() throws {
        XCTAssertTrue(app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0).waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForCenterMediaReady(timeout: 30),
            "Initial card should finish loading before switching pages"
        )

        switchToLouisville()

        XCTAssertTrue(
            app.staticTexts["Louisville"].waitForExistence(timeout: 10),
            "Louisville badge should become the front card after paging"
        )
        XCTAssertTrue(
            waitForCenterMediaReady(timeout: 20),
            "Loading spinner should clear after switching to Louisville"
        )
    }

    private func waitForCenterMediaReady(timeout: TimeInterval) -> Bool {
        let liveMap = app.otherElements["geokit-test-app.live-map"]
        if liveMap.waitForExistence(timeout: min(timeout, 5)) {
            return true
        }

        let loading = app.otherElements["geokit-test-app.card-loading"]
        guard loading.waitForExistence(timeout: 2) else {
            return true
        }

        let predicate = NSPredicate(format: "exists == false")
        return XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: predicate, object: loading)],
            timeout: timeout
        ) == .completed
    }

    private func switchToLouisville() {
        let root = app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0)
        XCTAssertTrue(root.waitForExistence(timeout: 10))
        let frame = root.frame
        let pageCount = 6
        let tapX = frame.minX + (frame.width / CGFloat(pageCount)) * 1.5
        let tapY = frame.maxY - 36
        app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: tapX, dy: tapY))
            .tap()
    }
}
