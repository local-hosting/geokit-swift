import Foundation

public enum MapContentRequestBuilder {
    public static func make(
        contentID: String,
        policy: MapStagePolicy,
        lifecycle: MapLifecycleState,
        isExpanded: Bool,
        title: String = "",
        mapStyleURI: String = "",
        preferredZoom: Double = 12,
        pins: [MapPin] = [],
        showUserPuck: Bool = false
    ) -> MapContentRequest {
        MapContentRequest(
            contentID: contentID,
            phase: MapContentPhaseResolver.resolve(MapLifecycleInput(policy: policy, lifecycle: lifecycle)),
            isExpanded: isExpanded,
            title: title,
            mapStyleURI: mapStyleURI,
            preferredZoom: preferredZoom,
            pins: pins,
            showUserPuck: showUserPuck
        )
    }
}
