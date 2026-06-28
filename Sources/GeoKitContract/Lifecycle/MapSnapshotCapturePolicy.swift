import Foundation

/// Retry budget for collapsed snapshot capture — Mapbox and Apple share the same policy.
public enum MapSnapshotCapturePolicy {
    public static let maxAttempts = 2
    public static let retryDelayMilliseconds = 400

    /// Cheap HTTP / off-GPU peek for cold boot and fan cards — never contends with the live map.
    public static let bootstrapPeekPriority: MapSnapshotPriority = .background

    /// Full-viewport GPU snapshot for expand transitions — matches live camera framing.
    public static let expansionPeekPriority: MapSnapshotPriority = .top

    public static func shouldScheduleRetry(failureCount: Int) -> Bool {
        failureCount < maxAttempts
    }
}
