#if os(iOS)
import CoreGraphics
import UIKit

/// Card storage surface for GeoKit peek snapshots (Mapbox or Apple). Host apps implement on their card model.
@MainActor
public protocol GeoKitMapSnapshotCard: AnyObject {
    var id: String { get }
    var mapProviderSnapshotCache: GeoKitMapProviderSnapshotCache { get }
    func mapSnapshotRequest(provider: MapProviderId, cameraFrame: MapCameraFrame?) -> MapContentRequest
    func mapSnapshotStorageDidChange()
}

public extension GeoKitMapSnapshotCard {
    func frozenSnapshot(for provider: MapProviderId) -> UIImage? {
        mapProviderSnapshotCache.snapshot(for: provider)
    }

    func hasUsableSnapshot(for provider: MapProviderId, cameraFrame: MapCameraFrame?) -> Bool {
        let request = mapSnapshotRequest(provider: provider, cameraFrame: cameraFrame)
        return mapProviderSnapshotCache.isSnapshotCurrent(
            for: provider,
            currentCamera: cameraFrame,
            selectedPinId: request.selectedPinId
        )
    }

    func setFrozenSnapshot(
        _ image: UIImage?,
        for provider: MapProviderId,
        cameraFrame: MapCameraFrame,
        selectedPinId: UUID? = nil
    ) {
        mapProviderSnapshotCache.setSnapshot(
            image,
            for: provider,
            cameraFrame: cameraFrame,
            selectedPinId: selectedPinId
        )
        mapSnapshotStorageDidChange()
    }

    func mapSnapshotSize(for provider: MapProviderId) -> CGSize {
        mapProviderSnapshotCache.snapshotSize(for: provider)
    }

    func setMapSnapshotSize(_ size: CGSize, for provider: MapProviderId) {
        mapProviderSnapshotCache.setSnapshotSize(size, for: provider)
    }

    func isSnapshotPrefetchScheduled(for provider: MapProviderId) -> Bool {
        mapProviderSnapshotCache.isPrefetchScheduled(for: provider)
    }

    func setSnapshotPrefetchScheduled(_ scheduled: Bool, for provider: MapProviderId) {
        mapProviderSnapshotCache.setPrefetchScheduled(scheduled, for: provider)
    }

    func mapSnapshotStorageDidChange() {}
}
#endif
