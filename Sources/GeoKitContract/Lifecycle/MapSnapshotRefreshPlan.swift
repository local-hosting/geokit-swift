import CoreGraphics
import Foundation

public enum MapSnapshotRefreshPlan {
    public static func shouldRefresh(
        layoutSize: CGSize,
        cacheKey: String,
        lastCacheKey: String?,
        hasSnapshot: Bool
    ) -> Bool {
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: layoutSize) else {
            return false
        }
        if cacheKey == lastCacheKey, hasSnapshot {
            return false
        }
        return true
    }

    public static func shouldShowFailedCapturePlaceholder(
        hasSnapshot: Bool,
        captureAttemptsExhausted: Bool
    ) -> Bool {
        captureAttemptsExhausted && !hasSnapshot
    }
}
