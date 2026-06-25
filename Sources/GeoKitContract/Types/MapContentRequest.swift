import Foundation

public enum MapContentPhase: String, Sendable, Equatable {
    case placeholder
    case snapshot
    case live
}

public struct MapContentRequest: Sendable, Equatable, Identifiable {
    public var id: String
    public var phase: MapContentPhase
    public var isExpanded: Bool
    public var title: String
    public var mapStyleURI: String
    public var preferredZoom: Double
    public var pins: [MapPin]
    public var showUserPuck: Bool
    /// Per-map override; when nil, `GeoKitMapProviderRegistry.defaultProvider` is used.
    public var mapProviderId: MapProviderId?

    public init(
        id: String,
        phase: MapContentPhase,
        isExpanded: Bool,
        title: String = "",
        mapStyleURI: String = "",
        preferredZoom: Double = 12,
        pins: [MapPin] = [],
        showUserPuck: Bool = false,
        mapProviderId: MapProviderId? = nil
    ) {
        self.id = id
        self.phase = phase
        self.isExpanded = isExpanded
        self.title = title
        self.mapStyleURI = mapStyleURI
        self.preferredZoom = preferredZoom
        self.pins = pins
        self.showUserPuck = showUserPuck
        self.mapProviderId = mapProviderId
    }
}
