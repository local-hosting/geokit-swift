import AccordDesignSystem
import CoreLocation
import GeoKitContract
#if os(iOS)
import UIKit
#endif

@MainActor
final class GeoKitDemoCard: AXCardModel, GeoKitMapSnapshotCard {
    let pins: [MapPin]

#if os(iOS)
    @Published var frozenSnapshot: UIImage?
    @Published var isMapRendered = false
    /// Latest live-map camera — preserved across expand/collapse remounts.
    @Published var lastCameraFrame: MapCameraFrame?
    var mapSnapshotSize: CGSize = .zero
    var snapshotCaptureTask: Task<Void, Never>?
    var snapshotPrefetchScheduled = false
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

    func mapSnapshotRequest(provider: MapProviderId) -> MapContentRequest {
        mapRequest(
            isExpanded: false,
            allowsLiveMount: false,
            isCenterSlot: false,
            mapProviderId: provider,
            cameraFrame: lastCameraFrame
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
            snapshotPriority: isCenterSlot ? .top : .background
        )
    }
}

