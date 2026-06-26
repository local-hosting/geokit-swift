import AccordDesignSystem
import CoreLocation
import GeoKitContract
#if os(iOS)
import UIKit
#endif

@MainActor
final class GeoKitDemoCard: AXCardModel, GeoKitMapSnapshotCard {
    let pins: [MapPin]
    let mapProviderSnapshotCache = GeoKitMapProviderSnapshotCache()

#if os(iOS)
    private var mapRenderedByProvider: [MapProviderId: Bool] = [:]
    /// Open pin callout — preserved across expand/collapse remounts.
    @Published var selectedPinId: UUID?
    var snapshotCaptureTask: Task<Void, Never>?
    var isPreparingTransitionSnapshot = false

#endif

    init(
        id: String,
        title: String,
        subtitle: String,
        pins: [MapPin]
    ) {
        self.pins = pins
        super.init(id: id, title: title, subtitle: subtitle)
    }

    func mapSnapshotStorageDidChange() {
        objectWillChange.send()
    }

    func isMapRendered(for provider: MapProviderId) -> Bool {
        mapRenderedByProvider[provider] ?? false
    }

    func setMapRendered(_ rendered: Bool, for provider: MapProviderId) {
        guard mapRenderedByProvider[provider] != rendered else { return }
        mapRenderedByProvider[provider] = rendered
        objectWillChange.send()
    }

    func clearMapRendered() {
        guard !mapRenderedByProvider.isEmpty else { return }
        mapRenderedByProvider.removeAll()
        objectWillChange.send()
    }

    func mapSnapshotRequest(provider: MapProviderId, cameraFrame: MapCameraFrame?) -> MapContentRequest {
        mapRequest(
            isExpanded: false,
            allowsLiveMount: false,
            isCenterSlot: false,
            mapProviderId: provider,
            cameraFrame: cameraFrame
        )
    }

    func mapRequest(
        isExpanded: Bool,
        allowsLiveMount: Bool,
        isCenterSlot: Bool,
        mapProviderId: MapProviderId,
        cameraFrame: MapCameraFrame? = nil
    ) -> MapContentRequest {
        MapContentRequest(
            id: id,
            phase: (isExpanded || allowsLiveMount) ? .live : .snapshot,
            isExpanded: isExpanded,
            title: title,
            mapStyleURI: GeoKitDemoConstants.mapStyleURI,
            preferredZoom: 12,
            pins: pins,
            showUserPuck: false,
            mapProviderId: mapProviderId,
            cameraFrame: cameraFrame,
            selectedPinId: selectedPinId,
            snapshotPriority: isCenterSlot ? .top : .background
        )
    }
}
