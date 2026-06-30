#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

import CoreLocation
import GeoKitContract
import MapKit
import SwiftUI

enum GeoKitMapKitCamera {
    static let collapsedPitch: Double = MapCameraFrameResolver.collapsedPitch

    static func initialPosition(
        coordinates: [CLLocationCoordinate2D],
        preferredZoom: Double
    ) -> MapCameraPosition {
        guard let focus = coordinates.first else {
            return .automatic
        }
        let center = centerCoordinate(from: coordinates) ?? focus
        return position(
            center: center,
            zoom: preferredZoom,
            bearing: 0,
            pitch: collapsedPitch
        )
    }

    static func from(_ frame: MapCameraFrame) -> MapCameraPosition {
        position(
            center: CLLocationCoordinate2D(latitude: frame.centerLatitude, longitude: frame.centerLongitude),
            zoom: frame.zoom,
            bearing: frame.bearing,
            pitch: frame.pitch
        )
    }

    static func frame(from camera: MapCamera) -> MapCameraFrame {
        MapCameraFrame(
            centerLatitude: camera.centerCoordinate.latitude,
            centerLongitude: camera.centerCoordinate.longitude,
            zoom: zoom(fromDistance: camera.distance, latitude: camera.centerCoordinate.latitude),
            bearing: camera.heading,
            pitch: camera.pitch
        )
    }

    private static func position(
        center: CLLocationCoordinate2D,
        zoom: Double,
        bearing: Double,
        pitch: Double
    ) -> MapCameraPosition {
        .camera(
            MapCamera(
                centerCoordinate: center,
                distance: distanceMeters(forZoom: zoom, latitude: center.latitude),
                heading: bearing,
                pitch: pitch
            )
        )
    }

    static func distanceMeters(forZoom zoom: Double, latitude: Double) -> CLLocationDistance {
        let metersPerPixel = 156543.03392 * cos(latitude * .pi / 180) / pow(2.0, zoom)
        return metersPerPixel * 512
    }

    static func zoom(fromDistance distance: CLLocationDistance, latitude: Double) -> Double {
        let metersPerPixel = distance / 512
        return log2(156543.03392 * cos(latitude * .pi / 180) / metersPerPixel)
    }

    static func centerCoordinate(from coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
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

extension AppleMapsProviderConfig.MapStyle {
    var mapKitStyle: MapStyle {
        switch self {
        case .standard:
            return .standard(elevation: .realistic)
        case .imagery:
            return .imagery(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic)
        }
    }
}
#endif
