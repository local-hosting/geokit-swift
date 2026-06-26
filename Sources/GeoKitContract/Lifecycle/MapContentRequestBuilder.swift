import Foundation

public enum MapContentRequestBuilder {
    public static func make(
        id: String,
        policy: MapStagePolicy,
        lifecycle: MapLifecycleState,
        isExpanded: Bool,
        title: String = "",
        mapStyleURI: String = "",
        preferredZoom: Double = 12,
        pins: [MapPin] = [],
        showUserPuck: Bool = false,
        mapProviderId: MapProviderId? = nil,
        cameraFrame: MapCameraFrame? = nil,
        selectedPinId: UUID? = nil,
        snapshotPriority: MapSnapshotPriority? = nil
    ) -> MapContentRequest {
        MapContentRequest(
            id: id,
            phase: MapContentPhaseResolver.resolve(MapLifecycleInput(policy: policy, lifecycle: lifecycle)),
            isExpanded: isExpanded,
            title: title,
            mapStyleURI: mapStyleURI,
            preferredZoom: preferredZoom,
            pins: pins,
            showUserPuck: showUserPuck,
            mapProviderId: mapProviderId,
            cameraFrame: cameraFrame,
            selectedPinId: selectedPinId,
            snapshotPriority: snapshotPriority ?? Self.snapshotPriority(for: policy)
        )
    }
}


extension MapContentRequestBuilder {
    public static func snapshotPriority(for policy: MapStagePolicy) -> MapSnapshotPriority {
        switch policy.stage {
        case .peek:
            return .background
        case .center, .expand:
            return .top
        }
    }
}
