import Foundation

public enum MapSnapshotCaptureExecutor {
    public static func captureWithRetry<T: Sendable>(
        capture: @Sendable () async throws -> T?
    ) async throws -> T? {
        var failureCount = 0
        while true {
            if Task.isCancelled { return nil }
            do {
                if let value = try await capture() {
                    return value
                }
            } catch {
                throw error
            }
            failureCount += 1
            guard MapSnapshotCapturePolicy.shouldScheduleRetry(failureCount: failureCount) else {
                return nil
            }
            try await Task.sleep(nanoseconds: UInt64(MapSnapshotCapturePolicy.retryDelayMilliseconds) * 1_000_000)
        }
    }
}
