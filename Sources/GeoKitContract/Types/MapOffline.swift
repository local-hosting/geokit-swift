import Foundation

/// How long per-`mapId` camera and pin selection should survive.
public enum MapLocalPersistScope: String, Sendable, Equatable, Codable, CaseIterable {
    /// In-memory only — cleared when the host process ends.
    case memory
    /// Tab / scene session — survives remounts, not app restart.
    case session
    /// Survives app restart until cleared or TTL (default for product maps).
    case durable
}

/// Provider-neutral camera + UI selection restored per map instance.
public struct MapLocalState: Sendable, Equatable, Codable {
    public var mapId: String
    public var cameraFrame: MapCameraFrame?
    public var selectedPinId: UUID?
    public var updatedAt: Date
    public var persistScope: MapLocalPersistScope

    public init(
        mapId: String,
        cameraFrame: MapCameraFrame? = nil,
        selectedPinId: UUID? = nil,
        updatedAt: Date = Date(),
        persistScope: MapLocalPersistScope = .durable
    ) {
        self.mapId = mapId
        self.cameraFrame = cameraFrame
        self.selectedPinId = selectedPinId
        self.updatedAt = updatedAt
        self.persistScope = persistScope
    }
}

/// Axis-aligned bounds in WGS84 degrees — west/east are longitude, south/north are latitude.
public struct MapOfflineBounds: Sendable, Equatable, Codable {
    public var south: Double
    public var west: Double
    public var north: Double
    public var east: Double

    public init(south: Double, west: Double, north: Double, east: Double) {
        self.south = south
        self.west = west
        self.north = north
        self.east = east
    }
}

public struct MapOfflineZoomRange: Sendable, Equatable, Codable {
    public var minZoom: Int
    public var maxZoom: Int

    public init(minZoom: Int, maxZoom: Int) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
    }
}

/// Host-facing offline behavior — implementations differ by platform (Mapbox TileStore vs web cache).
public enum MapOfflinePolicy: String, Sendable, Equatable, Codable, CaseIterable {
    /// Network required for live map tiles.
    case onlineOnly
    /// Prefer cached tiles when coverage is sufficient.
    case cacheFirst
    /// Show last snapshot when live tiles are unavailable.
    case snapshotFallback
}

public enum MapOfflineRegionStatus: String, Sendable, Equatable, Codable, CaseIterable {
    case idle
    case downloading
    case partial
    case ready
    case failed
}

/// Storage guardrails for prefetch — hosts may tighten; geokit enforces defaults.
public struct MapOfflineStorageBudget: Sendable, Equatable, Codable {
    public var maxBytes: Int64
    public var maxPrefetchZoom: Int
    public var maxTileCount: Int?

    public init(maxBytes: Int64, maxPrefetchZoom: Int, maxTileCount: Int? = nil) {
        self.maxBytes = maxBytes
        self.maxPrefetchZoom = maxPrefetchZoom
        self.maxTileCount = maxTileCount
    }
}

public enum MapOfflinePlatform: String, Sendable, Equatable, Codable, CaseIterable {
    case web
    case nativeMapbox
    case nativeMapKit
}

/// Host-provided offline area to prefetch when a map context loads (Tier D).
public struct MapOfflineContextLoad: Sendable, Equatable, Codable {
    public var bounds: MapOfflineBounds
    public var zoomRange: MapOfflineZoomRange?
    public var policy: MapOfflinePolicy
    public var providerHint: String?

    public init(
        bounds: MapOfflineBounds,
        zoomRange: MapOfflineZoomRange? = nil,
        policy: MapOfflinePolicy = .cacheFirst,
        providerHint: String? = nil
    ) {
        self.bounds = bounds
        self.zoomRange = zoomRange
        self.policy = policy
        self.providerHint = providerHint
    }
}

/// Request to prefetch map tiles for an area. Domain data (venues, markers) stays outside geokit.
public struct MapOfflinePrefetchRequest: Sendable, Equatable, Codable {
    public var mapId: String
    public var bounds: MapOfflineBounds
    public var zoomRange: MapOfflineZoomRange
    /// Optional provider hint (`mapbox`, `maptiler`, `apple`) — opaque to contract validation.
    public var providerHint: String?
    public var budget: MapOfflineStorageBudget?

    public init(
        mapId: String,
        bounds: MapOfflineBounds,
        zoomRange: MapOfflineZoomRange,
        providerHint: String? = nil,
        budget: MapOfflineStorageBudget? = nil
    ) {
        self.mapId = mapId
        self.bounds = bounds
        self.zoomRange = zoomRange
        self.providerHint = providerHint
        self.budget = budget
    }
}

/// Coverage report for a viewport — used to choose live vs snapshot phase.
public struct MapOfflineCoverage: Sendable, Equatable, Codable {
    public var status: MapOfflineRegionStatus
    /// Fraction of required tiles present in cache, 0…1.
    public var fractionComplete: Double
    public var tilesCached: Int
    public var tilesRequired: Int
    public var recommendsLiveMap: Bool
    public var recommendsSnapshotFallback: Bool

    public init(
        status: MapOfflineRegionStatus,
        fractionComplete: Double,
        tilesCached: Int,
        tilesRequired: Int,
        recommendsLiveMap: Bool,
        recommendsSnapshotFallback: Bool
    ) {
        self.status = status
        self.fractionComplete = fractionComplete
        self.tilesCached = tilesCached
        self.tilesRequired = tilesRequired
        self.recommendsLiveMap = recommendsLiveMap
        self.recommendsSnapshotFallback = recommendsSnapshotFallback
    }
}

public enum MapOfflineDefaults {
    public static let durablePersistScope: MapLocalPersistScope = .durable
    public static let webStorageBudget = MapOfflineStorageBudget(
        maxBytes: 200 * 1024 * 1024,
        maxPrefetchZoom: 15,
        maxTileCount: 8_000
    )
    public static let nativeMapboxStorageBudget = MapOfflineStorageBudget(
        maxBytes: 500 * 1024 * 1024,
        maxPrefetchZoom: 17,
        maxTileCount: nil
    )
    public static let liveMapCoverageThreshold = 0.8
    public static let snapshotFallbackCoverageThreshold = 0.5
    public static let snapshotMaxBytesPerMap = 2 * 1024 * 1024
    public static let snapshotMaxBytesTotal = 20 * 1024 * 1024
}
