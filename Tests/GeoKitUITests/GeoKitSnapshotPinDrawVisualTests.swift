#if os(iOS) || os(macOS)

import CoreLocation
import GeoKitContract
import GeoKitUI
import SwiftUI
import XCTest

@MainActor
final class GeoKitSnapshotPinDrawVisualTests: XCTestCase {
    private let primaryPinID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let secondaryPinID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    func testCompositeSingleSelectedPrimaryPin() {
        let base = GeoKitVisualTestImageFactory.solidBaseImage()
        let anchor = CGPoint(x: base.size.width / 2, y: base.size.height * 0.62)
        let pin = MapPin(
            id: primaryPinID,
            latitude: 40.7128,
            longitude: -74.006,
            pinHeading: "Primary",
            pinSubheading: "Selected",
            icon: "mappin.circle.fill",
            isPrimary: true
        )

        let composite = GeoKitSnapshotPinDraw.composite(
            baseImage: base,
            pins: [pin],
            pointForCoordinate: { _ in anchor },
            selectedPinId: primaryPinID,
            zoom: 14
        )

        GeoKitVisualSnapshotAssert.assertSnapshot(
            composite,
            named: "SnapshotPinDraw-SingleSelectedPrimaryPin",
            testCase: self
        )
    }

    func testCompositeTwoPinsSelectedSecondaryOnTop() {
        let base = GeoKitVisualTestImageFactory.solidBaseImage()
        let leftAnchor = CGPoint(x: base.size.width * 0.38, y: base.size.height * 0.58)
        let rightAnchor = CGPoint(x: base.size.width * 0.62, y: base.size.height * 0.58)
        let primary = MapPin(
            id: primaryPinID,
            latitude: 40.7128,
            longitude: -74.006,
            pinHeading: "Primary",
            pinSubheading: "Unselected",
            icon: "mappin.circle.fill",
            isPrimary: true
        )
        let secondary = MapPin(
            id: secondaryPinID,
            latitude: 40.7138,
            longitude: -74.004,
            pinHeading: "Secondary",
            pinSubheading: "Selected",
            icon: "leaf.fill",
            isPrimary: false
        )

        let composite = GeoKitSnapshotPinDraw.composite(
            baseImage: base,
            pins: [primary, secondary],
            pointForCoordinate: { coordinate in
                coordinate.longitude < -74.005 ? leftAnchor : rightAnchor
            },
            selectedPinId: secondaryPinID,
            zoom: 14
        )

        GeoKitVisualSnapshotAssert.assertSnapshot(
            composite,
            named: "SnapshotPinDraw-TwoPinsSelectedSecondary",
            testCase: self
        )
    }

    func testCompositeDotFallbackOrientation() {
        let base = GeoKitVisualTestImageFactory.solidBaseImage()
        let anchor = CGPoint(x: base.size.width / 2, y: base.size.height * 0.65)
        let pin = MapPin(
            id: primaryPinID,
            latitude: 40.7128,
            longitude: -74.006,
            pinHeading: "Dot",
            pinSubheading: "Fallback",
            icon: "mappin.circle.fill",
            isPrimary: true
        )

        #if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat()
        format.scale = GeoKitVisualTestImageFactory.renderScale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: base.size, format: format)
        let composite = renderer.image { context in
            base.draw(at: .zero)
            GeoKitSnapshotPinDraw.draw(
                pins: [pin],
                in: context.cgContext,
                pointForCoordinate: { _ in anchor },
                selectedPinId: nil,
                zoom: 14,
                scale: GeoKitVisualTestImageFactory.renderScale,
                renderPinImages: false
            )
        }
        #elseif canImport(AppKit)
        let size = base.size
        let scale = GeoKitVisualTestImageFactory.renderScale
        let composite = NSImage(size: size)
        composite.lockFocusFlipped(true)
        base.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        if let context = NSGraphicsContext.current?.cgContext {
            GeoKitSnapshotPinDraw.draw(
                pins: [pin],
                in: context,
                pointForCoordinate: { _ in anchor },
                selectedPinId: nil,
                zoom: 14,
                scale: scale,
                renderPinImages: false
            )
        }
        composite.unlockFocus()
        #endif

        GeoKitVisualSnapshotAssert.assertSnapshot(
            composite,
            named: "SnapshotPinDraw-DotFallbackOrientation",
            testCase: self
        )
    }
}

#endif
