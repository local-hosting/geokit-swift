#if os(iOS) || os(visionOS)

import MapboxMaps

/// Loads the host Studio style without overriding import configuration baked in Mapbox Studio.
enum GeoKitMapboxMapStyle {
    static func liveMapStyle(styleURI: String) -> MapStyle {
        guard let uri = StyleURI(rawValue: styleURI) else {
            preconditionFailure("Invalid Mapbox style URI: \(styleURI)")
        }
        return MapStyle(uri: uri)
    }
}
#endif
