#if os(iOS)
import CoreLocation
import MapboxMaps

enum GeoKitMapViewport {
    static let collapsedPitch: Double = 50

    static func initial(
        coordinates: [CLLocationCoordinate2D],
        preferredZoom: Double
    ) -> Viewport {
        guard let focus = coordinates.first else {
            return .idle
        }
        let center = centerCoordinate(from: coordinates) ?? focus
        return .camera(
            center: center,
            zoom: preferredZoom,
            bearing: 0,
            pitch: collapsedPitch
        )
    }

    private static func centerCoordinate(from coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        guard !coordinates.isEmpty else { return nil }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max()
        else {
            return nil
        }
        return CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
    }
}
#endif
