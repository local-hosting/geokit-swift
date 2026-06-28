#if os(iOS)
import GeoKitContract
import UIKit

/// Per-card static snapshot orchestration — one capture at a time per card, event-driven waits (no queue).
@MainActor
public final class GeoKitCardMapMediaController: GeoKitMapSnapshotControlling {
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
        cameraFrame: MapCameraFrame? = nil,
        onLoadingChanged: ((Bool) -> Void)? = nil,
        forceRecapture: Bool = false,
        matchesLiveViewport: Bool = false
    ) async {
        while !Task.isCancelled {
            let canStart = canStartSnapshotCapture(for: provider, priority: priority)
            let hasSnapshot = forceRecapture
                ? false
                : card.hasUsableSnapshot(for: provider, cameraFrame: cameraFrame)
            let action = MapSnapshotRetryPolicy.nextAction(
                hasSnapshot: hasSnapshot,
                isPrefetchScheduled: card.isSnapshotPrefetchScheduled(for: provider),
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
                await waitUntilSnapshotCaptureAllowed(for: provider, priority: priority)
            case .capture:
                await performCapture(
                    card: card,
                    size: size,
                    provider: provider,
                    priority: priority,
                    cameraFrame: cameraFrame,
                    onLoadingChanged: onLoadingChanged,
                    matchesLiveViewport: matchesLiveViewport,
                    forceRecapture: forceRecapture
                )
                if card.hasUsableSnapshot(for: provider, cameraFrame: cameraFrame) { return }
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
        cameraFrame: MapCameraFrame?,
        onLoadingChanged: ((Bool) -> Void)?,
        matchesLiveViewport: Bool,
        forceRecapture: Bool
    ) async {
        let captureSize = resolvedCaptureSize(
            card: card,
            provider: provider,
            fallback: size,
            forceRecapture: forceRecapture
        )
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: captureSize) else { return }

        card.setSnapshotPrefetchScheduled(true, for: provider)
        onLoadingChanged?(true)
        defer {
            card.setSnapshotPrefetchScheduled(false, for: provider)
            onLoadingChanged?(false)
        }

        if card.mapSnapshotSize(for: provider) != captureSize {
            card.setMapSnapshotSize(captureSize, for: provider)
        }

        await waitUntilSnapshotCaptureAllowed(for: provider, priority: priority)
        guard !Task.isCancelled else { return }

        let request = card.mapSnapshotRequest(
            provider: provider,
            cameraFrame: cameraFrame,
            matchesLiveViewport: matchesLiveViewport
        )
        let image: UIImage?
        do {
            image = try await MapSnapshotCaptureExecutor.captureWithRetry {
                try await GeoKitCardSnapshotCapture.capture(
                    request: request,
                    size: captureSize,
                    priority: priority
                )
            }
        } catch {
            fputs(
                "[GeoKitCardMapMediaController] snapshot capture failed card=\(card.id) provider=\(provider.rawValue) error=\(error)\n",
                stderr
            )
            return
        }

        // Commit a completed capture even if the owning task was cancelled while it ran.
        // Cancellation should stop starting new work, not discard a finished result — otherwise
        // sub-pixel layout churn cancels the task mid-capture, the snapshot is thrown away, and
        // the card never promotes to live (infinite re-capture, permanent loading spinner).
        guard let image else { return }
        let resolvedCamera = MapCameraFrameResolver.resolve(for: request)
        card.setFrozenSnapshot(
            image,
            for: provider,
            cameraFrame: resolvedCamera,
            selectedPinId: request.selectedPinId
        )
    }

    private func resolvedCaptureSize(
        card: any GeoKitMapSnapshotCard,
        provider: MapProviderId,
        fallback: CGSize,
        forceRecapture: Bool
    ) -> CGSize {
        if forceRecapture {
            return fallback
        }
        let storedSize = card.mapSnapshotSize(for: provider)
        if MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: storedSize) {
            return storedSize
        }
        return fallback
    }

    private func canStartSnapshotCapture(for provider: MapProviderId, priority: MapSnapshotPriority) -> Bool {
        // Background (fan) captures fetch a flat image over HTTP — no GPU, so they are
        // never gated behind the live Metal map.
        if priority == .background { return true }
        guard MapSnapshotCaptureGate.requiresLiveMapSafeWindow(for: provider) else { return true }
        return LiveMapSnapshotCoordinator.canStartSnapshotCapture()
    }

    private func waitUntilSnapshotCaptureAllowed(for provider: MapProviderId, priority: MapSnapshotPriority) async {
        if priority == .background { return }
        guard MapSnapshotCaptureGate.requiresLiveMapSafeWindow(for: provider) else { return }
        guard !LiveMapSnapshotCoordinator.canStartSnapshotCapture() else { return }
        try? await LiveMapSnapshotCoordinator.waitUntilSafeForSnapshot()
    }
}
#endif
