#if os(iOS) || os(macOS)

@testable import GeoKitUI
import SwiftUI
import XCTest

@MainActor
final class GeoKitCalloutAnchorVisualTests: XCTestCase {
    func testCalloutBottomAnchor() {
        let image = renderCallout(
            anchor: .bottom,
            label: "Bottom tail"
        )
        GeoKitVisualSnapshotAssert.assertSnapshot(
            image,
            named: "CalloutAnchor-Bottom",
            testCase: self
        )
    }

    func testCalloutTopRightAnchor() {
        let image = renderCallout(
            anchor: .topRight,
            label: "Top right"
        )
        GeoKitVisualSnapshotAssert.assertSnapshot(
            image,
            named: "CalloutAnchor-TopRight",
            testCase: self
        )
    }

    private func renderCallout(anchor: GeoKitCalloutAnchor, label: String) -> GeoKitPlatformImage {
        let content = Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(GeoKitMapTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .geoKitCallout(
                anchor: anchor,
                color: .white,
                borderColor: GeoKitMapTheme.accent,
                tailSize: 8,
                cornerRadius: 8,
                borderWidth: 2
            )
            .padding(16)
            .background(Color(red: 0.92, green: 0.94, blue: 0.97))
            .frame(width: 160, height: 120)

        let renderer = ImageRenderer(content: content)
        renderer.scale = GeoKitVisualTestImageFactory.renderScale
        #if canImport(UIKit)
        guard let image = renderer.uiImage else {
            fatalError("ImageRenderer failed to produce UIImage for callout visual test")
        }
        return image
        #elseif canImport(AppKit)
        guard let image = renderer.nsImage else {
            fatalError("ImageRenderer failed to produce NSImage for callout visual test")
        }
        return image
        #endif
    }
}

#endif
