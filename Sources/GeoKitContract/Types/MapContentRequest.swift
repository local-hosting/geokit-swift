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
    /// Host-persisted pin selection (callout open) restored when the live map remounts.
    public var selectedPinId: UUID?
    /// Front-card captures jump ahead of peek/background snapshot work.
    public var snapshotPriority: MapSnapshotPriority
    /// Host-owned token bumped when live pin coordinates change — forces map content refresh.
    public var livePinGeometryEpoch: Int
    /// Tier D — prefetch tiles for this area when the map context loads.
    public var offlineContext: MapOfflineContextLoad?

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
        selectedPinId: UUID? = nil,
        snapshotPriority: MapSnapshotPriority = .background,
        livePinGeometryEpoch: Int = 0,
        offlineContext: MapOfflineContextLoad? = nil
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
        self.selectedPinId = selectedPinId
        self.snapshotPriority = snapshotPriority
        self.livePinGeometryEpoch = livePinGeometryEpoch
        self.offlineContext = offlineContext
    }

    /// Full-screen live maps only — collapsed cards and transition snapshots pass touches to host chrome.
    public var mapAcceptsUserInteraction: Bool {
        isExpanded && phase == .live
    }
}
