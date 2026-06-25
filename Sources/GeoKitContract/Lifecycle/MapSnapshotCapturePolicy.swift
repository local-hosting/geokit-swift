import Foundation

/// Retry budget for collapsed snapshot capture — Mapbox and Apple share the same policy.
public enum MapSnapshotCapturePolicy {
    public static let maxAttempts = 2
    public static let retryDelayMilliseconds = 400

    public static func shouldScheduleRetry(failureCount: Int) -> Bool {
        failureCount < maxAttempts
    }
}
