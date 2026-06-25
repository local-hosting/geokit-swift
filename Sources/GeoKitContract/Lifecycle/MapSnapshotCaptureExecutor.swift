import Foundation

public enum MapSnapshotCaptureExecutor {
    public static func captureWithRetry<T: Sendable>(
        capture: @Sendable () async -> T?
    ) async -> T? {
        var failureCount = 0
        while true {
            if Task.isCancelled { return nil }
            if let value = await capture() {
                return value
            }
            failureCount += 1
            guard MapSnapshotCapturePolicy.shouldScheduleRetry(failureCount: failureCount) else {
                return nil
            }
            try? await Task.sleep(nanoseconds: UInt64(MapSnapshotCapturePolicy.retryDelayMilliseconds) * 1_000_000)
        }
    }
}
