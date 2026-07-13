#if canImport(UIKit)
import SwiftUI
import UIKit

/// Suppresses Mapbox/MapKit UIKit surfaces from the accessibility tree.
///
/// Host apps (Accord ``ax-map-live-surface``, ``ax-media-slot-shell``) own semantic probes.
/// Platform map views can publish screen-space accessibility frames that lag SwiftUI card
/// transforms during collection drag — XCTest then reads stale geometry for the live map.
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

    /// Mapbox ``MapView`` keeps UIKit hit-testing even when SwiftUI ``allowsHitTesting(false)``.
    /// Disable the platform subtree so collapsed inline maps do not steal card taps/drags.
    static func setMapSurfaceUserInteractionEnabled(_ enabled: Bool, from anchor: UIView) {
        let root = hostingRoot(from: anchor)
        applyMapSurfaceUserInteraction(enabled, in: root)
        for delay in [0.0, 0.05, 0.2] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                applyMapSurfaceUserInteraction(enabled, in: root)
            }
        }
    }

    private static func hostingRoot(from anchor: UIView) -> UIView {
        var root = anchor
        for _ in 0..<12 {
            guard let superview = root.superview else { break }
            root = superview
            let name = String(describing: type(of: root))
            if name.contains("HostingView") || name.contains("HostingController") {
                break
            }
        }
        return root
    }

    private static func applyMapSurfaceUserInteraction(_ enabled: Bool, in root: UIView) {
        let queue = [root]
        var i = 0
        var views = queue
        while i < views.count {
            let view = views[i]
            i += 1
            let name = String(describing: type(of: view))
            let isMapSurface =
                name.contains("MapView")
                || name.contains("Mapbox")
                || name.contains("MGL")
                || name.contains("Metal")
                || name.contains("ViewAnnotation")
                || name.contains("Annotation")
            if isMapSurface {
                view.isUserInteractionEnabled = enabled
            }
            views.append(contentsOf: view.subviews)
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

private struct GeoKitPlatformMapUserInteractionAnchor: UIViewRepresentable {
    var enabled: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        GeoKitPlatformMapAccessibilitySuppressor.setMapSurfaceUserInteractionEnabled(enabled, from: uiView)
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

    /// Collapsed maps must not steal card chrome taps — Mapbox ignores SwiftUI ``allowsHitTesting(false)``.
    func geokitPlatformMapUserInteraction(_ enabled: Bool) -> some View {
        background(GeoKitPlatformMapUserInteractionAnchor(enabled: enabled))
    }
}
#endif
