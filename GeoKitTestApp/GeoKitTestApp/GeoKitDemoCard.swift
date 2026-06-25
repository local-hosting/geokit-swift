import AccordDesignSystem
import GeoKitContract

@MainActor
final class GeoKitDemoCard: AXCardModel {
    let pins: [MapPin]

    init(
        id: String,
        title: String,
        subtitle: String,
        pins: [MapPin]
    ) {
        self.pins = pins
        super.init(id: id, title: title, subtitle: subtitle)
    }

    func mapRequest(isExpanded: Bool) -> MapContentRequest {
        MapContentRequest(
            contentID: id,
            phase: isExpanded ? .live : .snapshot,
            isExpanded: isExpanded,
            title: title,
            mapStyleURI: GeoKitDemoConstants.mapStyleURI,
            preferredZoom: 12,
            pins: pins,
            showUserPuck: false
        )
    }
}
