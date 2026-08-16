#if canImport(UIKit)
import UIKit
import XCTest

@testable import GeoKitUI

final class GeoKitMapAccessibilityTests: XCTestCase {
    func testSuppressHidesSubtreeFromAccessibility() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let mapHost = UIView(frame: CGRect(x: 10, y: 10, width: 180, height: 180))
        mapHost.isAccessibilityElement = true
        root.addSubview(mapHost)

        GeoKitPlatformMapAccessibilitySuppressor.suppress(in: mapHost)

        XCTAssertFalse(mapHost.isAccessibilityElement)
        XCTAssertTrue(mapHost.accessibilityElementsHidden)
    }

    func testSuppressSiblingsDoesNotHideAnchor() {
        let superview = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let anchor = UIView(frame: .zero)
        anchor.isAccessibilityElement = true
        let mapHost = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        mapHost.isAccessibilityElement = true
        superview.addSubview(mapHost)
        superview.addSubview(anchor)

        GeoKitPlatformMapAccessibilitySuppressor.suppressSiblings(of: anchor)

        XCTAssertTrue(anchor.isAccessibilityElement)
        XCTAssertFalse(anchor.accessibilityElementsHidden)
        XCTAssertFalse(mapHost.isAccessibilityElement)
        XCTAssertTrue(mapHost.accessibilityElementsHidden)
    }
}
#endif
