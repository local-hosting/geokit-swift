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
        mapProviderId: MapProviderId? = nil
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
            mapProviderId: mapProviderId
        )
    }
}
