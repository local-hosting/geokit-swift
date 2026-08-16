#if os(iOS) || os(visionOS)

import MapboxMaps

/// Ensures Mapbox Standard import transit labels match Studio / static snapshot rendering on live GL.
enum GeoKitMapboxStyleImportConfigurator {
    private static let transitLabelsConfigKey = "showTransitLabels"
    private static let fallbackImportIds = ["basemap", "standard"]

    @MainActor
    static func applyTransitLabels(on map: MapboxMap) {
        var importIds = map.styleImports.map(\.id)
        for fallback in fallbackImportIds where !importIds.contains(fallback) {
            importIds.append(fallback)
        }
        for importId in importIds {
            applyTransitLabels(on: map, importId: importId)
        }
    }

    @MainActor
    private static func applyTransitLabels(on map: MapboxMap, importId: String) {
        do {
            try map.setStyleImportConfigProperty(
                for: importId,
                config: transitLabelsConfigKey,
                value: true
            )
        } catch {
            // Style import does not expose Standard transit config — ignore classic-only styles.
        }
    }
}
#endif
