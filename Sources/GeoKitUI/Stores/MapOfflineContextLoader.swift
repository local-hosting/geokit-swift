import Foundation
import GeoKitContract

/// Tier D — prefetch offline tiles when map context loads.
@MainActor
public enum MapOfflineContextLoader {
    private static var scheduledKeys = Set<String>()

    public static func resetForTesting() {
        scheduledKeys.removeAll()
    }

    public static func loadIfNeeded(for request: MapContentRequest) {
        guard let context = request.offlineContext else { return }
        prefetchRegion(bounds: context.bounds, for: request, context: context)
    }

    public static func prefetchRegion(
        bounds: MapOfflineBounds,
        for request: MapContentRequest,
        context: MapOfflineContextLoad? = nil,
        zoomRange: MapOfflineZoomRange? = nil,
    ) {
        let resolvedContext = context ?? request.offlineContext
        let platform: MapOfflinePlatform
        switch MapProviderResolver.resolve(for: request) {
        case .mapbox:
            platform = .nativeMapbox
        case .apple:
            platform = .nativeMapKit
        }
        let zoom = zoomRange
            ?? resolvedContext?.zoomRange
            ?? MapOfflinePolicyResolver.defaultZoomRange(for: request.preferredZoom, platform: platform)
        let key = "\(request.id):\(bounds.south),\(bounds.west),\(bounds.north),\(bounds.east)"
        guard !scheduledKeys.contains(key) else { return }
        scheduledKeys.insert(key)

        let prefetchRequest: MapOfflinePrefetchRequest
        do {
            prefetchRequest = try MapOfflinePolicyResolver.validate(
                request: MapOfflinePrefetchRequest(
                    mapId: request.id,
                    bounds: bounds,
                    zoomRange: zoom,
                    providerHint: resolvedContext?.providerHint,
                    budget: nil
                ),
                platform: platform
            )
        } catch {
            scheduledKeys.remove(key)
            return
        }

        guard platform != .nativeMapKit else { return }
        GeoKitRuntime.prefetchOfflineRegionOnContextLoad?(prefetchRequest, request)
    }
}
