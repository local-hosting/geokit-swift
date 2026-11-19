import Foundation

/// Top-level offline contract API — mirrors `geokit/src/core/src/contract/offline.ts` export names.

public func validateOfflineBounds(_ bounds: MapOfflineBounds) throws {
    try MapOfflinePolicyResolver.validate(bounds: bounds)
}

public func defaultOfflineBudget(for platform: MapOfflinePlatform) -> MapOfflineStorageBudget {
    MapOfflinePolicyResolver.defaultBudget(for: platform)
}

public func normalizeOfflineZoomRange(
    _ range: MapOfflineZoomRange,
    platform: MapOfflinePlatform
) -> MapOfflineZoomRange {
    MapOfflinePolicyResolver.normalizeZoomRange(range, platform: platform)
}

public func enumerateOfflineTileCoordinates(
    bounds: MapOfflineBounds,
    zoomRange: MapOfflineZoomRange
) -> [MapOfflineTileCoordinate] {
    MapOfflinePolicyResolver.enumerateTileCoordinates(bounds: bounds, zoomRange: zoomRange)
}

public func defaultOfflineZoomRangeForMap(
    centerZoom: Double,
    platform: MapOfflinePlatform = .web
) -> MapOfflineZoomRange {
    MapOfflinePolicyResolver.defaultZoomRange(for: centerZoom, platform: platform)
}

public func resolveOfflineBoundsFromPins(_ pins: [MapPin], padding: Double = 0.01) -> MapOfflineBounds? {
    MapOfflinePolicyResolver.boundsFromPins(pins, padding: padding)
}

public func buildOfflineTileUrl(template: String, tile: MapOfflineTileCoordinate) -> String {
    template
        .replacingOccurrences(of: "{z}", with: String(tile.z))
        .replacingOccurrences(of: "{x}", with: String(tile.x))
        .replacingOccurrences(of: "{y}", with: String(tile.y))
}

public func estimateOfflineTileCount(
    bounds: MapOfflineBounds,
    zoomRange: MapOfflineZoomRange
) -> Int {
    MapOfflinePolicyResolver.estimateTileCount(bounds: bounds, zoomRange: zoomRange)
}

public func offlineRegionStatus(fractionComplete: Double) -> MapOfflineRegionStatus {
    MapOfflinePolicyResolver.regionStatus(fractionComplete: fractionComplete)
}

public func resolveOfflineCoverage(
    tilesCached: Int,
    tilesRequired: Int,
    policy: MapOfflinePolicy
) -> MapOfflineCoverage {
    MapOfflinePolicyResolver.coverage(
        tilesCached: tilesCached,
        tilesRequired: tilesRequired,
        policy: policy
    )
}

public func validateOfflinePrefetchRequest(
    _ request: MapOfflinePrefetchRequest,
    platform: MapOfflinePlatform
) throws -> MapOfflinePrefetchRequest {
    try MapOfflinePolicyResolver.validate(request: request, platform: platform)
}