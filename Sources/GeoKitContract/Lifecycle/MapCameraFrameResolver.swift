import Foundation

/// Derives the provider-neutral camera a map request will render — shared by Mapbox and MapKit.
public enum MapCameraFrameResolver {
    public static let defaultPitch: Double = 50

    public static func resolve(for request: MapContentRequest) -> MapCameraFrame {
        if let cameraFrame = request.cameraFrame {
            return cameraFrame
        }
        return initialFrame(
            pins: request.pins,
            preferredZoom: request.preferredZoom
        )
    }

    public static func initialFrame(
        pins: [MapPin],
        preferredZoom: Double
    ) -> MapCameraFrame {
        let center = centerCoordinate(from: pins) ?? defaultCenter(from: pins)
        return MapCameraFrame(
            centerLatitude: center.latitude,
            centerLongitude: center.longitude,
            zoom: preferredZoom,
            bearing: 0,
            pitch: defaultPitch
        )
    }

    private static func centerCoordinate(from pins: [MapPin]) -> (latitude: Double, longitude: Double)? {
        guard !pins.isEmpty else { return nil }
        let lats = pins.map(\.latitude)
        let lons = pins.map(\.longitude)
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max()
        else {
            return nil
        }
        return (
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
    }

    private static func defaultCenter(from pins: [MapPin]) -> (latitude: Double, longitude: Double) {
        if let first = pins.first {
            return (first.latitude, first.longitude)
        }
        return (0, 0)
    }
}
