import CoreGraphics
import Foundation

/// Live geo pins stay on the map surface — no snapshot bake / hide cycle during card springs.
public enum MapPinTransitionCoverPolicy {
    public static func hideLiveMapPins(
        mapIsTransitioning: Bool,
        pinsLayoutSettling: Bool,
        livePainted: Bool = false
    ) -> Bool {
        _ = mapIsTransitioning
        _ = pinsLayoutSettling
        _ = livePainted
        return false
    }

    /// Peek snapshot covers live tiles only until the first live paint — never again after.
    public static func snapshotCoversLive(
        mapIsTransitioning: Bool,
        pinsLayoutSettling: Bool,
        livePainted: Bool
    ) -> Bool {
        _ = mapIsTransitioning
        _ = pinsLayoutSettling
        return !livePainted
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
