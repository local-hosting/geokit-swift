import XCTest

final class GeoKitDemoMapRegressionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        app.launch()
    }

    func testSwitchToAppleMapsRendersCenterMedia() throws {
        XCTAssertTrue(app.otherElements["geokit-test-app.root"].waitForExistence(timeout: 10))
        XCTAssertTrue(waitForCenterMediaReady(timeout: 45))

        app.buttons["Apple"].tap()

        XCTAssertTrue(
            waitForCenterMediaReady(timeout: 45),
            "Apple Maps provider must reach snapshot or live paint"
        )
    }

    func testExpandCollapseKeepsMapReady() throws {
        XCTAssertTrue(app.otherElements["geokit-test-app.root"].waitForExistence(timeout: 10))
        XCTAssertTrue(waitForCenterMediaReady(timeout: 45))

        let root = app.otherElements.matching(identifier: "geokit-test-app.root").element(boundBy: 0)
        root.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42)).tap()
        let collapse = app.buttons["geokit-collapse-button"]
        XCTAssertTrue(collapse.waitForExistence(timeout: 8))
        collapse.tap()

        let collapsed = element(matching: "geokit-test-app.collapsed-map")
        XCTAssertTrue(collapsed.waitForExistence(timeout: 12), "Map should return to collapsed state")
        XCTAssertTrue(collapse.waitForNonExistence(timeout: 8), "Collapse control should hide when collapsed")
        XCTAssertTrue(app.staticTexts["New York"].waitForExistence(timeout: 8))
        XCTAssertTrue(
            app.staticTexts["City Hall"].waitForExistence(timeout: 8),
            "Default NYC pin heading should remain visible after collapse"
        )
    }

    func testMapDoesNotFlashWhiteWhileCentering() throws {
        XCTAssertTrue(app.otherElements["geokit-test-app.root"].waitForExistence(timeout: 10))

        let screen = XCUIScreen.main
        var maxWhiteFraction = 0.0
        let deadline = Date().addingTimeInterval(6)
        while Date() < deadline {
            let fraction = GeoKitMapFlashSampler.nearWhiteFraction(screen.screenshot().image)
            maxWhiteFraction = max(maxWhiteFraction, fraction)
        }

        XCTAssertLessThan(
            maxWhiteFraction,
            GeoKitMapFlashSampler.flashThreshold,
            "Map flashed near-white while centering (fraction \(maxWhiteFraction))"
        )
    }

    func testMultiPinSelectionUpdatesHeading() throws {
        XCTAssertTrue(app.otherElements["geokit-test-app.root"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["New York"].waitForExistence(timeout: 8))
        XCTAssertTrue(waitForCenterMediaReady(timeout: 45))

        let brooklynPinID = "a2a2a2a2-a2a2-a2a2-a2a2-a2a2a2a2a2a2"
        let brooklyn = element(matching: "geokit-test-app.pin-\(brooklynPinID)")
        let brooklynByLabel = app.buttons["Brooklyn Bridge"]
        let pinControl = brooklyn.waitForExistence(timeout: 2) ? brooklyn : brooklynByLabel
        XCTAssertTrue(
            pinControl.waitForExistence(timeout: 8),
            "Secondary pin control should be visible on NYC"
        )
        pinControl.tap()

        let heading = element(matching: "geokit-test-app.selected-pin-heading")
        XCTAssertTrue(
            heading.waitForExistence(timeout: 8),
            "Selected pin heading should update after choosing Brooklyn Bridge"
        )
        XCTAssertEqual(heading.label, "Brooklyn Bridge")
    }

    private func element(matching identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func centerMediaReadyElement() -> XCUIElement {
        element(matching: "geokit-test-app.center-media-ready")
    }

    private func waitForCenterMediaReady(timeout: TimeInterval) -> Bool {
        centerMediaReadyElement().waitForExistence(timeout: timeout)
    }
}

enum GeoKitMapFlashSampler {
    static let flashThreshold = 0.97

    static func nearWhiteFraction(_ image: UIImage) -> Double {
        guard let source = image.cgImage else { return 0 }
        let side = 32
        let bytesPerRow = side * 4
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        guard let context = CGContext(
            data: &pixels,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0 }

        let w = CGFloat(source.width)
        let h = CGFloat(source.height)
        let crop = CGRect(x: w * 0.30, y: h * 0.30, width: w * 0.40, height: h * 0.30)
        guard let cropped = source.cropping(to: crop) else { return 0 }
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: side, height: side))

        var nearWhite = 0
        let total = side * side
        for index in 0..<total {
            let base = index * 4
            let r = pixels[base], g = pixels[base + 1], b = pixels[base + 2]
            if r >= 240, g >= 240, b >= 240 { nearWhite += 1 }
        }
        return Double(nearWhite) / Double(total)
    }
}
