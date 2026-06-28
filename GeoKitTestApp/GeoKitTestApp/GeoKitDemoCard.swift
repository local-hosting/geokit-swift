import AccordDesignSystem
import CoreLocation
import GeoKitContract
import GeoKitUI
#if os(iOS)
import UIKit
#endif

@MainActor
final class GeoKitDemoCard: AXCardModel, GeoKitMapSnapshotCard, GeoKitLiveMapCard {
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
        mapSnapshotRequest(provider: provider, cameraFrame: cameraFrame, matchesLiveViewport: false)
    }

    func mapSnapshotRequest(
        provider: MapProviderId,
        cameraFrame: MapCameraFrame?,
        matchesLiveViewport: Bool
    ) -> MapContentRequest {
        mapRequest(
            isExpanded: matchesLiveViewport,
            allowsLiveMount: matchesLiveViewport,
            isCenterSlot: matchesLiveViewport,
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
        let usesLiveStyle = isExpanded || allowsLiveMount
        return MapContentRequest(
            id: id,
            phase: usesLiveStyle ? .live : .snapshot,
            isExpanded: isExpanded,
            title: title,
            mapStyleURI: usesLiveStyle
                ? GeoKitDemoConstants.liveMapStyleURI
                : GeoKitDemoConstants.snapshotMapStyleURI,
            preferredZoom: 12,
            pins: pins,
            showUserPuck: false,
            mapProviderId: mapProviderId,
            cameraFrame: cameraFrame,
            selectedPinId: selectedPinId,
            snapshotPriority: isCenterSlot ? .top : .background
        )
    }

    func liveMapRequest(
        isExpanded: Bool,
        mapProviderId: MapProviderId,
        cameraFrame: MapCameraFrame? = nil
    ) -> MapContentRequest {
        mapRequest(
            isExpanded: isExpanded,
            allowsLiveMount: true,
            isCenterSlot: !isExpanded,
            mapProviderId: mapProviderId,
            cameraFrame: cameraFrame
        )
    }
}

