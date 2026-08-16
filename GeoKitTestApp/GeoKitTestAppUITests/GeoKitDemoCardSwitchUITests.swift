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
            waitForCenterMediaReady(timeout: 45),
            "Front card should show a snapshot or painted live map"
        )
    }

    func testSwitchToLouisvilleClearsLoadingSpinner() throws {
        XCTAssertTrue(app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0).waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForCenterMediaReady(timeout: 45),
            "Initial card should finish loading before switching pages"
        )

        switchToLouisville()

        XCTAssertTrue(
            app.staticTexts["Louisville"].waitForExistence(timeout: 10),
            "Louisville badge should become the front card after paging"
        )
        XCTAssertTrue(
            waitForCenterMediaReady(timeout: 45),
            "Loading spinner should clear after switching to Louisville"
        )
    }

    func testSwitchBackToNewYorkShowsLiveMap() throws {
        XCTAssertTrue(app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0).waitForExistence(timeout: 10))
        XCTAssertTrue(waitForCenterMediaReady(timeout: 45))

        switchToLouisville()
        XCTAssertTrue(app.staticTexts["Louisville"].waitForExistence(timeout: 10))
        XCTAssertTrue(waitForCenterMediaReady(timeout: 45))

        switchToPage(index: 0)
        XCTAssertTrue(app.staticTexts["New York"].waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForCenterMediaReady(timeout: 45),
            "Returning to New York must mount the live map — not a blank card dead-end"
        )
    }

    func testExpandCardKeepsFooterBadgeAndHidesProviderPicker() throws {
        XCTAssertTrue(app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0).waitForExistence(timeout: 10))
        XCTAssertTrue(waitForCenterMediaReady(timeout: 45))

        let root = app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0)
        root.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42)).tap()

        let picker = app.otherElements["geokit-test-app.map-provider-picker"]
        let expanded = picker.waitForNonExistence(timeout: 8) || !picker.isHittable
        XCTAssertTrue(expanded, "Map provider picker should hide when the card expands")

        let badge = app.staticTexts["New York"]
        XCTAssertTrue(badge.waitForExistence(timeout: 5), "Footer badge should remain visible when expanded")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "expanded-full-screen-card"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func centerMediaReadyElement() -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "geokit-test-app.center-media-ready").firstMatch
    }

    private func waitForCenterMediaReady(timeout: TimeInterval) -> Bool {
        centerMediaReadyElement().waitForExistence(timeout: timeout)
    }

    private let placeIDs = ["nyc-map", "louisville-map", "chicago-map", "austin-map", "seattle-map", "miami-map"]

    private func switchToPage(index: Int) {
        guard placeIDs.indices.contains(index) else {
            XCTFail("Unknown page index \(index)")
            return
        }
        let select = app.buttons["geokit-test-app.select-\(placeIDs[index])"]
        if select.waitForExistence(timeout: 5) {
            select.tap()
            return
        }
        let page = app.descendants(matching: .any).matching(identifier: "geokit-test-app.page-\(index)").firstMatch
        if page.waitForExistence(timeout: 5), page.isHittable {
            page.tap()
            return
        }
        let root = app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0)
        XCTAssertTrue(root.waitForExistence(timeout: 10))
        let frame = root.frame
        let pageCount = placeIDs.count
        let tapX = frame.minX + (frame.width / CGFloat(pageCount)) * (CGFloat(index) + 0.5)
        let tapY = frame.maxY - 22
        app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: tapX, dy: tapY))
            .tap()
    }

    private func switchToLouisville() {
        switchToPage(index: 1)
    }
}
