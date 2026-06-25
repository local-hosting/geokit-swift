#if os(iOS)
import GeoKitContract
import GeoKitCore
import UIKit

/// Per-card static snapshot orchestration — one capture at a time per card, event-driven waits (no queue).
@MainActor
public final class GeoKitCardMapMediaController {
    public static let shared = GeoKitCardMapMediaController()

    private let reachability: GeoKitReachabilityMonitor

    public init(reachability: GeoKitReachabilityMonitor = .shared) {
        self.reachability = reachability
        self.reachability.start()
    }

    /// Captures a peek snapshot once for `card`, suspending on live-map gate or offline until an event resumes.
    public func ensureStaticSnapshot(
        for card: any GeoKitMapSnapshotCard,
        size: CGSize,
        provider: MapProviderId,
        priority: MapSnapshotPriority = .background,
        onLoadingChanged: ((Bool) -> Void)? = nil
    ) async {
        while !Task.isCancelled {
            let canStart = canStartSnapshotCapture(for: provider)
            let action = MapSnapshotRetryPolicy.nextAction(
                hasSnapshot: card.frozenSnapshot != nil,
                isPrefetchScheduled: card.snapshotPrefetchScheduled,
                provider: provider,
                canStartSnapshotCapture: canStart,
                isOnline: reachability.isOnline
            )
            switch action {
            case .skip:
                return
            case .waitForNetwork:
                await reachability.waitUntilOnline()
            case .waitForLiveMapSafe:
                await waitUntilSnapshotCaptureAllowed(for: provider)
            case .capture:
                await performCapture(
                    card: card,
                    size: size,
                    provider: provider,
                    priority: priority,
                    onLoadingChanged: onLoadingChanged
                )
                if card.frozenSnapshot != nil { return }
                if !reachability.isOnline {
                    await reachability.waitUntilOnline()
                } else {
                    return
                }
            }
        }
    }

    private func performCapture(
        card: any GeoKitMapSnapshotCard,
        size: CGSize,
        provider: MapProviderId,
        priority: MapSnapshotPriority,
        onLoadingChanged: ((Bool) -> Void)?
    ) async {
        let captureSize = resolvedCaptureSize(card: card, fallback: size)
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: captureSize) else { return }

        card.snapshotPrefetchScheduled = true
        onLoadingChanged?(true)
        defer {
            card.snapshotPrefetchScheduled = false
            onLoadingChanged?(false)
        }

        if card.mapSnapshotSize != captureSize {
            card.mapSnapshotSize = captureSize
        }

        await waitUntilSnapshotCaptureAllowed(for: provider)
        guard !Task.isCancelled else { return }

        let request = card.mapSnapshotRequest(provider: provider)
        let image = await MapSnapshotCaptureExecutor.captureWithRetry {
            await GeoKitCardSnapshotCapture.capture(
                request: request,
                size: captureSize,
                priority: priority
            )
        }

        // Commit a completed capture even if the owning task was cancelled while it ran.
        // Cancellation should stop starting new work, not discard a finished result — otherwise
        // sub-pixel layout churn cancels the task mid-capture, the snapshot is thrown away, and
        // the card never promotes to live (infinite re-capture, permanent loading spinner).
        guard let image else { return }
        card.frozenSnapshot = image
    }

    private func resolvedCaptureSize(card: any GeoKitMapSnapshotCard, fallback: CGSize) -> CGSize {
        if MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: card.mapSnapshotSize) {
            return card.mapSnapshotSize
        }
        return fallback
    }

    private func canStartSnapshotCapture(for provider: MapProviderId) -> Bool {
        guard MapSnapshotCaptureGate.requiresLiveMapSafeWindow(for: provider) else { return true }
        return GeoKitMapboxLiveMapRegistry.canStartSnapshotCapture
    }

    private func waitUntilSnapshotCaptureAllowed(for provider: MapProviderId) async {
        guard MapSnapshotCaptureGate.requiresLiveMapSafeWindow(for: provider) else { return }
        guard !GeoKitMapboxLiveMapRegistry.canStartSnapshotCapture else { return }
        try? await GeoKitMapboxLiveMapRegistry.waitUntilSafeForSnapshot()
    }
}
#endif
