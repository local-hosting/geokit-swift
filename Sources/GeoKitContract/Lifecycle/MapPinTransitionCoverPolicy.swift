import CoreGraphics
import Foundation

/// When geo-projected map pins should hide and a static peek snapshot (with baked pins) covers the live surface.
public enum MapPinTransitionCoverPolicy {
    /// Hide ``MapViewAnnotation`` / MapKit annotations while the card spring or a post-spring layout resize runs.
    public static func hideLiveMapPins(
        mapIsTransitioning: Bool,
        pinsLayoutSettling: Bool
    ) -> Bool {
        mapIsTransitioning || pinsLayoutSettling
    }

    /// Keep the card-slot peek snapshot opaque on top of live tiles during card transitions or before first paint.
    /// Steady-state layout settling hides live pins only — it must not pull the peek snapshot back over painted tiles.
    public static func snapshotCoversLive(
        mapIsTransitioning: Bool,
        pinsLayoutSettling: Bool,
        livePainted: Bool
    ) -> Bool {
        if mapIsTransitioning { return true }
        if !livePainted { return true }
        return false
    }
}

/// Detect layout jumps after expand/collapse scale transitions so pins can stay on the snapshot until ``onMapIdle``.
public enum MapPinLayoutSettlingPolicy {
    /// Ignore sub-point GeometryReader churn once live is mounted (matches card media refresh threshold).
    public static let minLayoutSizeDelta: CGFloat = 2

    public static func shouldBeginSettling(
        isTransitioning: Bool,
        previousSize: CGSize,
        newSize: CGSize,
        mapReady: Bool
    ) -> Bool {
        guard mapReady, !isTransitioning else { return false }
        guard MapSurfaceMountPolicy.isValidLayoutSize(previousSize),
              MapSurfaceMountPolicy.isValidLayoutSize(newSize)
        else { return false }
        let widthDelta = abs(newSize.width - previousSize.width)
        let heightDelta = abs(newSize.height - previousSize.height)
        return widthDelta > minLayoutSizeDelta || heightDelta > minLayoutSizeDelta
    }
}
