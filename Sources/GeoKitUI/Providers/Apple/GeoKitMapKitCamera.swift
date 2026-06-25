#if os(iOS)
import CoreLocation
import GeoKitContract
import MapKit
import SwiftUI

enum GeoKitMapKitCamera {
    static let collapsedPitch: Double = 50

    static func initialPosition(
        coordinates: [CLLocationCoordinate2D],
        preferredZoom: Double
    ) -> MapCameraPosition {
        guard let focus = coordinates.first else {
            return .automatic
        }
        let center = centerCoordinate(from: coordinates) ?? focus
        return .camera(
            MapCamera(
                centerCoordinate: center,
                distance: distanceMeters(forZoom: preferredZoom, latitude: center.latitude),
                heading: 0,
                pitch: collapsedPitch
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
