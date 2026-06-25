import Foundation

/// Next step for a per-card static snapshot attempt.
public enum MapSnapshotNextAction: Equatable, Sendable {
    case skip
    case waitForLiveMapSafe
    case waitForNetwork
    case capture
}

/// Pure decision policy for when a card should capture, wait, or skip.
public enum MapSnapshotRetryPolicy {
    public static func nextAction(
        hasSnapshot: Bool,
        isPrefetchScheduled: Bool,
        provider: MapProviderId,
        canStartSnapshotCapture: Bool,
        isOnline: Bool
    ) -> MapSnapshotNextAction {
        if hasSnapshot || isPrefetchScheduled { return .skip }
        if !isOnline { return .waitForNetwork }
        if MapSnapshotCaptureGate.shouldDeferCapture(
            provider: provider,
            liveMapActive: !canStartSnapshotCapture
        ) {
            return .waitForLiveMapSafe
        }
        return .capture
    }
}
