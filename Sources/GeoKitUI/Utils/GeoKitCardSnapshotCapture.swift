#if os(iOS)
import CoreLocation
import GeoKitContract
import MapboxMaps
import MapKit
import SwiftUI
import UIKit

/// Captures card peek snapshots for any registered map provider.
public enum GeoKitCardSnapshotCapture {
    public static func capture(
        request: MapContentRequest,
        size: CGSize,
        priority: MapSnapshotPriority = .background
    ) async -> UIImage? {
        let provider = request.mapProviderId ?? .mapbox
        switch provider {
        case .mapbox:
            return await captureMapbox(request: request, size: size, priority: priority)
        case .apple:
            return await captureApple(request: request, size: size)
        }
    }

    private static func captureMapbox(
        request: MapContentRequest,
        size: CGSize,
        priority: MapSnapshotPriority
    ) async -> UIImage? {
        let coordinates = request.pins.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        let viewport: Viewport
        if let frame = request.cameraFrame {
            viewport = GeoKitMapViewport.from(frame)
        } else {
            viewport = GeoKitMapViewport.initial(
                coordinates: coordinates,
                preferredZoom: request.preferredZoom
            )
        }
        return await GeoKitSnapshotService.capture(
            viewport: viewport,
            size: size,
            styleURI: request.mapStyleURI,
            priority: priority
        )
    }

    private static func captureApple(request: MapContentRequest, size: CGSize) async -> UIImage? {
        let coordinates = request.pins.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        let position: MapCameraPosition
        if let frame = request.cameraFrame {
            position = GeoKitMapKitCamera.from(frame)
        } else {
            position = GeoKitMapKitCamera.initialPosition(
                coordinates: coordinates,
                preferredZoom: request.preferredZoom
            )
        }
        let mapStyle = GeoKitMapProviderRegistry.apple.mapStyle
        return await GeoKitMapKitSnapshotService.capture(
            position: position,
            request: request,
            size: size,
            mapStyle: mapStyle
        )
    }
}
#endif
