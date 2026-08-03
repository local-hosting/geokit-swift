#if os(iOS) || os(visionOS)

import CoreLocation
import GeoKitContract
import UIKit

/// Projects coordinates onto a Mapbox Static Images bitmap (bearing 0, pitch 0).
enum GeoKitMapboxStaticImagePinProjection {
    static func pointForCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        frame: MapCameraFrame,
        imageSize: CGSize
    ) -> CGPoint {
        let center = CLLocationCoordinate2D(
            latitude: frame.centerLatitude,
            longitude: frame.centerLongitude
        )
        let scale = pow(2.0, frame.zoom)
        let cosLat = max(cos(center.latitude * .pi / 180.0), 0.01)
        let metersPerPixel = 156543.03392 * cosLat / scale

        let dLon = coordinate.longitude - center.longitude
        let dLat = coordinate.latitude - center.latitude
        let metersPerDegreeLat = 111_320.0
        let metersPerDegreeLon = 111_320.0 * cosLat

        let pixelX = Double(imageSize.width) / 2.0 + (dLon * metersPerDegreeLon) / metersPerPixel
        let pixelY = Double(imageSize.height) / 2.0 - (dLat * metersPerDegreeLat) / metersPerPixel
        return CGPoint(x: pixelX, y: pixelY)
    }
}
#endif
