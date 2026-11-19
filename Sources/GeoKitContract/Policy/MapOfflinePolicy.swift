import Foundation

public enum MapOfflinePolicyError: Error, Equatable, Sendable {
    case invalidBounds
    case invalidZoomRange
    case zoomRangeExceedsBudget(MapOfflineZoomRange, MapOfflineStorageBudget)
    case estimatedTileCountExceedsBudget(Int, Int)
}

/// Pure offline policy — no I/O, no provider SDKs.
public struct MapOfflineTileCoordinate: Sendable, Equatable, Codable {
    public var z: Int
    public var x: Int
    public var y: Int

    public init(z: Int, x: Int, y: Int) {
        self.z = z
        self.x = x
        self.y = y
    }
}

public enum MapOfflinePolicyResolver {
    public static func validateOfflineBounds(_ bounds: MapOfflineBounds) throws {
        try validate(bounds: bounds)
    }

    public static func defaultOfflineBudget(for platform: MapOfflinePlatform) -> MapOfflineStorageBudget {
        defaultBudget(for: platform)
    }

    public static func normalizeOfflineZoomRange(
        _ range: MapOfflineZoomRange,
        platform: MapOfflinePlatform
    ) -> MapOfflineZoomRange {
        normalizeZoomRange(range, platform: platform)
    }

    public static func estimateOfflineTileCount(
        bounds: MapOfflineBounds,
        zoomRange: MapOfflineZoomRange
    ) -> Int {
        estimateTileCount(bounds: bounds, zoomRange: zoomRange)
    }

    public static func offlineRegionStatus(fractionComplete: Double) -> MapOfflineRegionStatus {
        regionStatus(fractionComplete: fractionComplete)
    }

    public static func resolveOfflineCoverage(
        tilesCached: Int,
        tilesRequired: Int,
        policy: MapOfflinePolicy
    ) -> MapOfflineCoverage {
        coverage(tilesCached: tilesCached, tilesRequired: tilesRequired, policy: policy)
    }

    public static func validateOfflinePrefetchRequest(
        _ request: MapOfflinePrefetchRequest,
        platform: MapOfflinePlatform
    ) throws -> MapOfflinePrefetchRequest {
        try validate(request: request, platform: platform)
    }

    public static func enumerateOfflineTileCoordinates(
        bounds: MapOfflineBounds,
        zoomRange: MapOfflineZoomRange
    ) -> [MapOfflineTileCoordinate] {
        enumerateTileCoordinates(bounds: bounds, zoomRange: zoomRange)
    }

    public static func defaultOfflineZoomRangeForMap(
        centerZoom: Double,
        platform: MapOfflinePlatform = .web
    ) -> MapOfflineZoomRange {
        defaultZoomRange(for: centerZoom, platform: platform)
    }

    public static func resolveOfflineBoundsFromPins(_ pins: [MapPin], padding: Double = 0.01) -> MapOfflineBounds? {
        boundsFromPins(pins, padding: padding)
    }

    public static func validate(bounds: MapOfflineBounds) throws {
        guard bounds.south < bounds.north,
              bounds.west < bounds.east,
              (-90 ... 90).contains(bounds.south),
              (-90 ... 90).contains(bounds.north),
              (-180 ... 180).contains(bounds.west),
              (-180 ... 180).contains(bounds.east)
        else {
            throw MapOfflinePolicyError.invalidBounds
        }
    }

    public static func normalizeZoomRange(
        _ range: MapOfflineZoomRange,
        platform: MapOfflinePlatform
    ) -> MapOfflineZoomRange {
        let minZoom = max(0, min(range.minZoom, range.maxZoom))
        let maxCap = platform == .web
            ? MapOfflineDefaults.webStorageBudget.maxPrefetchZoom
            : MapOfflineDefaults.nativeMapboxStorageBudget.maxPrefetchZoom
        let maxZoom = min(22, max(minZoom, min(range.maxZoom, maxCap)))
        return MapOfflineZoomRange(minZoom: minZoom, maxZoom: maxZoom)
    }

    public static func defaultBudget(for platform: MapOfflinePlatform) -> MapOfflineStorageBudget {
        switch platform {
        case .web:
            return MapOfflineDefaults.webStorageBudget
        case .nativeMapbox:
            return MapOfflineDefaults.nativeMapboxStorageBudget
        case .nativeMapKit:
            return MapOfflineStorageBudget(
                maxBytes: 0,
                maxPrefetchZoom: 0,
                maxTileCount: 0
            )
        }
    }

    public static func validate(
        request: MapOfflinePrefetchRequest,
        platform: MapOfflinePlatform
    ) throws -> MapOfflinePrefetchRequest {
        try validate(bounds: request.bounds)
        let budget = request.budget ?? defaultBudget(for: platform)
        let zoomRange = normalizeZoomRange(request.zoomRange, platform: platform)
        guard zoomRange.minZoom <= zoomRange.maxZoom else {
            throw MapOfflinePolicyError.invalidZoomRange
        }
        guard zoomRange.maxZoom <= budget.maxPrefetchZoom else {
            throw MapOfflinePolicyError.zoomRangeExceedsBudget(zoomRange, budget)
        }
        let tileCount = estimateTileCount(bounds: request.bounds, zoomRange: zoomRange)
        if let maxTileCount = budget.maxTileCount, tileCount > maxTileCount {
            throw MapOfflinePolicyError.estimatedTileCountExceedsBudget(tileCount, maxTileCount)
        }
        return MapOfflinePrefetchRequest(
            mapId: request.mapId,
            bounds: request.bounds,
            zoomRange: zoomRange,
            providerHint: request.providerHint,
            budget: budget
        )
    }

    public static func coverage(
        tilesCached: Int,
        tilesRequired: Int,
        policy: MapOfflinePolicy
    ) -> MapOfflineCoverage {
        let required = max(tilesRequired, 0)
        let cached = max(min(tilesCached, required), 0)
        let fraction = required == 0 ? 1.0 : Double(cached) / Double(required)
        let status = regionStatus(fractionComplete: fraction)
        let recommendsLive = policy != .onlineOnly
            && fraction >= MapOfflineDefaults.liveMapCoverageThreshold
        let recommendsSnapshot = policy == .snapshotFallback
            && fraction < MapOfflineDefaults.snapshotFallbackCoverageThreshold
        return MapOfflineCoverage(
            status: status,
            fractionComplete: fraction,
            tilesCached: cached,
            tilesRequired: required,
            recommendsLiveMap: recommendsLive,
            recommendsSnapshotFallback: recommendsSnapshot
        )
    }

    public static func regionStatus(fractionComplete: Double) -> MapOfflineRegionStatus {
        switch fractionComplete {
        case 0.95...:
            return .ready
        case 0.5 ..< 0.95:
            return .partial
        default:
            return .idle
        }
    }

    public static func defaultZoomRange(
        for centerZoom: Double,
        platform: MapOfflinePlatform = .web
    ) -> MapOfflineZoomRange {
        let budget = defaultBudget(for: platform)
        let maxZoom = min(Int(centerZoom.rounded()) + 1, budget.maxPrefetchZoom)
        let minZoom = max(0, maxZoom - 3)
        return MapOfflineZoomRange(minZoom: minZoom, maxZoom: maxZoom)
    }

    public static func boundsFromPins(_ pins: [MapPin], padding: Double = 0.01) -> MapOfflineBounds? {
        guard let first = pins.first else { return nil }
        var south = first.latitude
        var north = first.latitude
        var west = first.longitude
        var east = first.longitude
        for pin in pins {
            south = min(south, pin.latitude)
            north = max(north, pin.latitude)
            west = min(west, pin.longitude)
            east = max(east, pin.longitude)
        }
        return MapOfflineBounds(
            south: south - padding,
            west: west - padding,
            north: north + padding,
            east: east + padding
        )
    }

    public static func enumerateTileCoordinates(
        bounds: MapOfflineBounds,
        zoomRange: MapOfflineZoomRange
    ) -> [MapOfflineTileCoordinate] {
        guard bounds.south < bounds.north, bounds.west < bounds.east else { return [] }
        var tiles: [MapOfflineTileCoordinate] = []
        for zoom in zoomRange.minZoom ... zoomRange.maxZoom {
            let northWest = tileXY(latitude: bounds.north, longitude: bounds.west, zoom: zoom)
            let southEast = tileXY(latitude: bounds.south, longitude: bounds.east, zoom: zoom)
            for x in northWest.x ... southEast.x {
                for y in northWest.y ... southEast.y {
                    tiles.append(MapOfflineTileCoordinate(z: zoom, x: x, y: y))
                }
            }
        }
        return tiles
    }

    /// Rough Web-Mercator tile count for bbox × zoom levels (prefetch budget guard).
    public static func estimateTileCount(
        bounds: MapOfflineBounds,
        zoomRange: MapOfflineZoomRange
    ) -> Int {
        guard bounds.south < bounds.north, bounds.west < bounds.east else { return 0 }
        var total = 0
        for zoom in zoomRange.minZoom ... zoomRange.maxZoom {
            let northWest = tileXY(latitude: bounds.north, longitude: bounds.west, zoom: zoom)
            let southEast = tileXY(latitude: bounds.south, longitude: bounds.east, zoom: zoom)
            total += (southEast.x - northWest.x + 1) * (southEast.y - northWest.y + 1)
        }
        return max(total, 0)
    }


    private static func tileXY(latitude: Double, longitude: Double, zoom: Int) -> (x: Int, y: Int) {
        let scale = Double(1 << zoom)
        let x = Int(floor((longitude + 180.0) / 360.0 * scale))
        let latRad = latitude * .pi / 180.0
        let y = Int(floor((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / .pi) / 2.0 * scale))
        return (x, y)
    }
}
