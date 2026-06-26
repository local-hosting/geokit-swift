#if os(iOS)
import CoreGraphics
import UIKit

/// Per-map-provider peek snapshot storage — preserves Mapbox vs MapKit captures across provider toggles.
@MainActor
public final class GeoKitMapProviderSnapshotCache {
    private var snapshots: [MapProviderId: UIImage] = [:]
    private var snapshotCameras: [MapProviderId: MapCameraFrame] = [:]
    private var snapshotSizes: [MapProviderId: CGSize] = [:]
    private var snapshotSelectedPinIds: [MapProviderId: UUID] = [:]
    private var prefetchScheduled: Set<MapProviderId> = []

    public init() {}

    public func snapshot(for provider: MapProviderId) -> UIImage? {
        snapshots[provider]
    }

    public func snapshotCamera(for provider: MapProviderId) -> MapCameraFrame? {
        snapshotCameras[provider]
    }

    public func setSnapshot(
        _ image: UIImage?,
        for provider: MapProviderId,
        cameraFrame: MapCameraFrame,
        selectedPinId: UUID? = nil
    ) {
        if let image {
            snapshots[provider] = image
            snapshotCameras[provider] = cameraFrame
            if let selectedPinId {
                snapshotSelectedPinIds[provider] = selectedPinId
            } else {
                snapshotSelectedPinIds.removeValue(forKey: provider)
            }
        } else {
            removeSnapshot(for: provider)
        }
    }

    /// Peek snapshot is valid only when it matches the card's shared camera (same view on every provider).
    public func isSnapshotCurrent(
        for provider: MapProviderId,
        currentCamera: MapCameraFrame?,
        selectedPinId: UUID? = nil
    ) -> Bool {
        guard snapshot(for: provider) != nil, let capturedCamera = snapshotCameras[provider] else {
            return false
        }
        let capturedSelection = snapshotSelectedPinIds[provider]
        let selectionMatches = capturedSelection == selectedPinId
        guard let currentCamera else { return selectionMatches }
        return capturedCamera.isApproximatelyEqual(to: currentCamera) && selectionMatches
    }

    public func snapshotSize(for provider: MapProviderId) -> CGSize {
        snapshotSizes[provider] ?? .zero
    }

    public func setSnapshotSize(_ size: CGSize, for provider: MapProviderId) {
        snapshotSizes[provider] = size
    }

    public func isPrefetchScheduled(for provider: MapProviderId) -> Bool {
        prefetchScheduled.contains(provider)
    }

    public func setPrefetchScheduled(_ scheduled: Bool, for provider: MapProviderId) {
        if scheduled {
            prefetchScheduled.insert(provider)
        } else {
            prefetchScheduled.remove(provider)
        }
    }

    public func removeAll() {
        snapshots.removeAll()
        snapshotCameras.removeAll()
        snapshotSizes.removeAll()
        snapshotSelectedPinIds.removeAll()
        prefetchScheduled.removeAll()
    }

    public func removeSnapshot(for provider: MapProviderId) {
        snapshots.removeValue(forKey: provider)
        snapshotCameras.removeValue(forKey: provider)
        snapshotSizes.removeValue(forKey: provider)
        snapshotSelectedPinIds.removeValue(forKey: provider)
        prefetchScheduled.remove(provider)
    }
}
#endif
