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

    /// A live GL surface paints an opaque base the instant it mounts, compositing *above* any frozen
    /// underlay — so the underlay can never mask that base (the host handoff gray flash). Keep the live
    /// map underneath and hold a single cover *above* it until the surface has painted, then cross-fade. The
    /// cover spans both the pre-mount window and the mounted-but-unpainted window, so it is the only snapshot
    /// layer the surface needs. It shows the frozen snapshot when one exists (seamless continuity from the
    /// card image) and the dark placeholder otherwise (cold first load); the caller picks the content.
    public static func coversLiveSurface(livePainted: Bool) -> Bool {
        !livePainted
    }
}

/// Decides when the dark cover may lift to reveal the live map surface on first load.
///
/// Lifting on the *first* `onMapIdle` is wrong: that idle can fire at the style's default/world camera
/// before the camera flies to the card's pins, revealing an uncentered light map that then animates into
/// place — read as a white flash. The cover must hold until the live surface has painted **and** settled at
/// its intended camera. During expand/collapse the host drives framing, so settle-at-target isn't required.
public enum LiveMapRevealPolicy {
    public static func revealsLiveSurface(
        livePainted: Bool,
        cameraSettledAtTarget: Bool,
        isTransitioning: Bool
    ) -> Bool {
        guard livePainted else { return false }
        return isTransitioning || cameraSettledAtTarget
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
