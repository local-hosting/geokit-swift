import CardMediaContract
import CoreGraphics
import Foundation

/// Pure mount gates shared by Mapbox and Apple map surfaces — keeps blank white frames testable.
public enum MapSurfaceMountPolicy {
    public static let minLayoutSize: CGFloat = 128

    public static func isValidLayoutSize(_ size: CGSize) -> Bool {
        CardMediaSurfaceMountPolicy.isValidLayoutSize(size, minLayoutSize: minLayoutSize)
    }

    public static func canMountMap(surfaceReady: Bool, layoutSize: CGSize) -> Bool {
        CardMediaSurfaceMountPolicy.canMountLiveContent(
            surfaceReady: surfaceReady,
            layoutSize: layoutSize,
            minLayoutSize: minLayoutSize
        )
    }

    public static func shouldShowLiveMap(canMount: Bool, mapReady: Bool) -> Bool {
        CardMediaSurfaceMountPolicy.shouldShowLive(canMount: canMount, contentReady: mapReady)
    }

    public static func shouldBeginSnapshotCapture(layoutSize: CGSize) -> Bool {
        CardMediaSurfaceMountPolicy.shouldBeginSnapshotCapture(
            layoutSize: layoutSize,
            minLayoutSize: minLayoutSize
        )
    }
}
