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
    /// Optional seed camera preserved across provider switches; read once when a map surface mounts.
    public var cameraFrame: MapCameraFrame?
    /// Front-card captures jump ahead of peek/background snapshot work.
    public var snapshotPriority: MapSnapshotPriority

    public init(
        id: String,
        phase: MapContentPhase,
        isExpanded: Bool,
        title: String = "",
        mapStyleURI: String = "",
        preferredZoom: Double = 12,
        pins: [MapPin] = [],
        showUserPuck: Bool = false,
        mapProviderId: MapProviderId? = nil,
        cameraFrame: MapCameraFrame? = nil,
        snapshotPriority: MapSnapshotPriority = .background
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
        self.cameraFrame = cameraFrame
        self.snapshotPriority = snapshotPriority
    }

    /// Full-screen live maps only — collapsed cards and transition snapshots pass touches to host chrome.
    public var mapAcceptsUserInteraction: Bool {
        isExpanded && phase == .live
    }
}
