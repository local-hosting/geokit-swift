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
        let frame = MapCameraFrameResolver.resolve(for: request)
        let viewport = GeoKitMapViewport.from(frame)
        let zoom = frame.zoom
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
