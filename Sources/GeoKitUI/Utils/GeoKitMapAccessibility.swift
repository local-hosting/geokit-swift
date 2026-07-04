#if canImport(UIKit)
import SwiftUI
import UIKit

/// Suppresses Mapbox/MapKit UIKit surfaces from the accessibility tree.
///
/// Host apps (Accord ``ax-map-live-surface``, ``ax-media-slot-shell``) own semantic probes.
/// Platform map views can publish screen-space accessibility frames that lag SwiftUI card
/// transforms during deck/stack drag — XCTest then reads stale geometry for the live map.
enum GeoKitPlatformMapAccessibilitySuppressor {
    static func suppress(in view: UIView) {
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true
        for child in view.subviews {
            suppress(in: child)
        }
    }

    static func suppressSiblings(of anchor: UIView) {
        guard let superview = anchor.superview else { return }
        for sibling in superview.subviews where sibling !== anchor {
            suppress(in: sibling)
        }
    }
}

private struct GeoKitPlatformMapAccessibilityAnchor: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.refresh(around: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        func refresh(around anchor: UIView) {
            apply(around: anchor)
            // UIKit map hosting views can publish accessibility frames one layout pass behind
            // animated SwiftUI transforms — re-run on the next tick during drag/settle.
            DispatchQueue.main.async { [weak self, weak anchor] in
                guard let self, let anchor else { return }
                self.apply(around: anchor)
            }
        }

        private func apply(around anchor: UIView) {
            GeoKitPlatformMapAccessibilitySuppressor.suppressSiblings(of: anchor)
        }
    }
}

public extension View {
    /// Hides platform map UIKit surfaces so host-owned accessibility identifiers track SwiftUI layout.
    func geokitIsolatePlatformMapAccessibility() -> some View {
        self
            .accessibilityHidden(true)
            .accessibilityElement(children: .ignore)
            .background(GeoKitPlatformMapAccessibilityAnchor())
    }
}
#endif
