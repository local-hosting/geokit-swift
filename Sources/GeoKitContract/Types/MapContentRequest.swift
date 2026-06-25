import Foundation

public enum MapContentPhase: String, Sendable, Equatable {
    case placeholder
    case snapshot
    case live
}

public struct MapContentRequest: Sendable, Equatable {
    public var contentID: String
    public var phase: MapContentPhase
    public var isExpanded: Bool
    public var title: String
    public var mapStyleURI: String
    public var preferredZoom: Double
    public var pins: [MapPin]
    public var showUserPuck: Bool

    public init(
        contentID: String,
        phase: MapContentPhase,
        isExpanded: Bool,
        title: String = "",
        mapStyleURI: String = "",
        preferredZoom: Double = 12,
        pins: [MapPin] = [],
        showUserPuck: Bool = false
    ) {
        self.contentID = contentID
        self.phase = phase
        self.isExpanded = isExpanded
        self.title = title
        self.mapStyleURI = mapStyleURI
        self.preferredZoom = preferredZoom
        self.pins = pins
        self.showUserPuck = showUserPuck
    }
}
