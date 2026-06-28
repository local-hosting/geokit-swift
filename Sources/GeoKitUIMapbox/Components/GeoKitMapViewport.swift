#if os(iOS)
import CoreLocation
import GeoKitContract
import GeoKitUI
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
        return viewport(
            center: center,
            zoom: preferredZoom,
            bearing: 0,
            pitch: collapsedPitch
        )
    }

    static func from(_ frame: MapCameraFrame) -> Viewport {
        viewport(
            center: CLLocationCoordinate2D(latitude: frame.centerLatitude, longitude: frame.centerLongitude),
            zoom: frame.zoom,
            bearing: frame.bearing,
            pitch: frame.pitch
        )
    }

    static func frame(from viewport: Viewport) -> MapCameraFrame? {
        guard let camera = viewport.camera,
              let center = camera.center,
              let zoom = camera.zoom,
              let bearing = camera.bearing,
              let pitch = camera.pitch
        else {
            return nil
        }
        return MapCameraFrame(
            centerLatitude: center.latitude,
            centerLongitude: center.longitude,
            zoom: zoom,
            bearing: bearing,
            pitch: pitch
        )
    }

    private static func viewport(
        center: CLLocationCoordinate2D,
        zoom: Double,
        bearing: Double,
        pitch: Double
    ) -> Viewport {
        .camera(
            center: center,
            zoom: zoom,
            bearing: bearing,
            pitch: pitch
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
