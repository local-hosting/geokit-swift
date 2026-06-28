#if os(iOS)
import CoreLocation
import GeoKitContract
import GeoKitUI
import MapboxMaps
import UIKit

enum GeoKitCardSnapshotCaptureMapbox {
    static func capture(
        request: MapContentRequest,
        size: CGSize,
        priority: MapSnapshotPriority
    ) async throws -> UIImage? {
        // Back/fan cards fetch a flat image over HTTP so they never run the GPU
        // Snapshotter — only the live front card (.top) uses the on-device path.
        if priority == .background {
            return try await GeoKitMapboxStaticImageService.capture(request: request, size: size)
        }
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
        let zoom = request.cameraFrame?.zoom ?? Double(request.preferredZoom)
        return await GeoKitSnapshotService.capture(
            viewport: viewport,
            size: size,
            styleURI: request.mapStyleURI,
            priority: priority,
            pins: request.pins,
            selectedPinId: request.selectedPinId,
            zoom: zoom
        )
    }
}
#endif
