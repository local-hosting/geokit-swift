import CoreGraphics
import Foundation

/// Pure mount gates shared by Mapbox and Apple map surfaces — keeps blank white frames testable.
public enum MapSurfaceMountPolicy {
    public static let minLayoutSize: CGFloat = 128

    public static func isValidLayoutSize(_ size: CGSize) -> Bool {
        size.width >= minLayoutSize && size.height >= minLayoutSize
    }

    public static func canMountMap(surfaceReady: Bool, layoutSize: CGSize) -> Bool {
        surfaceReady && isValidLayoutSize(layoutSize)
    }

    public static func shouldShowLiveMap(canMount: Bool, mapReady: Bool) -> Bool {
        canMount && mapReady
    }

    /// Hero morph may briefly invalidate layout gates — keep a warm GL surface mounted.
    public static func retainsWarmMountDuringTransitionGap(
        isTransitioning: Bool,
        liveAlreadyPainted: Bool
    ) -> Bool {
        isTransitioning && liveAlreadyPainted
    }

    public static func shouldShowLiveMap(
        canMount: Bool,
        mapReady: Bool,
        isTransitioning: Bool,
        liveAlreadyPainted: Bool
    ) -> Bool {
        shouldShowLiveMap(canMount: canMount, mapReady: mapReady)
            || retainsWarmMountDuringTransitionGap(
                isTransitioning: isTransitioning,
                liveAlreadyPainted: liveAlreadyPainted
            )
    }

    public static func shouldBeginSnapshotCapture(layoutSize: CGSize) -> Bool {
        isValidLayoutSize(layoutSize)
    }
}
