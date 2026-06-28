#if canImport(UIKit) || canImport(AppKit)
import Combine
import Foundation
import GeoKitContract

/// Card model surface for one persistent external live map + peek snapshots (Places / GeoKitTestApp).
@MainActor
public protocol GeoKitLiveMapCard: GeoKitMapSnapshotCard, ObservableObject {
    var selectedPinId: UUID? { get set }
    func isMapRendered(for provider: MapProviderId) -> Bool
    func setMapRendered(_ rendered: Bool, for provider: MapProviderId)
    func liveMapRequest(
        isExpanded: Bool,
        mapProviderId: MapProviderId,
        cameraFrame: MapCameraFrame?
    ) -> MapContentRequest
}
#endif
