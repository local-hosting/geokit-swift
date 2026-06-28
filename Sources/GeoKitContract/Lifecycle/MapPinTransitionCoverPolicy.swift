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

    /// Keep the card-slot peek snapshot opaque on top of painted live tiles.
    public static func snapshotCoversLive(
        mapIsTransitioning: Bool,
        pinsLayoutSettling: Bool,
        livePainted: Bool
    ) -> Bool {
        if mapIsTransitioning || pinsLayoutSettling { return true }
        return !livePainted
    }
}

/// Detect layout jumps after expand/collapse scale transitions so pins can stay on the snapshot until ``onMapIdle``.
public enum MapPinLayoutSettlingPolicy {
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
        return previousSize != newSize
    }
}
