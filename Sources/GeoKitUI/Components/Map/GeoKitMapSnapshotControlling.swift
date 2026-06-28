#if canImport(UIKit) || canImport(AppKit)
import CoreGraphics
import GeoKitContract

/// Capture seam for ``GeoKitCenterCardMediaStore`` — real capture on iOS, fakes in tests.
@MainActor
public protocol GeoKitMapSnapshotControlling: AnyObject {
    /// Ensures `card` holds a usable peek snapshot for `provider`, suspending until capture is allowed.
    func ensureStaticSnapshot(
        for card: any GeoKitMapSnapshotCard,
        size: CGSize,
        provider: MapProviderId,
        priority: MapSnapshotPriority,
        cameraFrame: MapCameraFrame?,
        onLoadingChanged: ((Bool) -> Void)?,
        forceRecapture: Bool,
        matchesLiveViewport: Bool
    ) async
}

public extension GeoKitMapSnapshotControlling {
    func ensureStaticSnapshot(
        for card: any GeoKitMapSnapshotCard,
        size: CGSize,
        provider: MapProviderId,
        priority: MapSnapshotPriority = .background,
        cameraFrame: MapCameraFrame? = nil,
        onLoadingChanged: ((Bool) -> Void)? = nil
    ) async {
        await ensureStaticSnapshot(
            for: card,
            size: size,
            provider: provider,
            priority: priority,
            cameraFrame: cameraFrame,
            onLoadingChanged: onLoadingChanged,
            forceRecapture: false,
            matchesLiveViewport: false
        )
    }
}
#endif
