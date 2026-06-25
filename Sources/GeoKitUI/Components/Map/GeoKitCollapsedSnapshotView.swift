import CoreLocation
import GeoKitContract
import MapboxMaps
import SwiftUI

struct GeoKitCollapsedSnapshotView: View {
    let request: MapContentRequest
    @Binding var viewport: Viewport
    @Binding var snapshot: UIImage?
    @State private var lastCacheKey: String?
    @State private var refreshTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Color.white
                if let image = snapshot {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                }
            }
            .frame(width: size.width, height: size.height)
            .onAppear { refreshSnapshot(size: size) }
            .onChange(of: size) { _, newSize in refreshSnapshot(size: newSize) }
            .onChange(of: request.contentID) { _, _ in
                lastCacheKey = nil
                refreshSnapshot(size: size)
            }
        }
        .clipped()
        .preference(key: GeoKitLiveRenderingKey.self, value: false)
    }

    private func refreshSnapshot(size: CGSize) {
        guard size.width >= GeoKitMapLayout.minMapSize,
              size.height >= GeoKitMapLayout.minMapSize
        else { return }

        if case .idle = viewport {
            viewport = GeoKitMapViewport.initial(
                coordinates: request.pins.map(\.coordinate),
                preferredZoom: request.preferredZoom
            )
        }

        let cacheKey = snapshotCacheKey(size: size)
        if cacheKey == lastCacheKey, snapshot != nil { return }

        refreshTask?.cancel()
        refreshTask = Task {
            let styleURI = request.mapStyleURI
            let currentViewport = viewport
            let image = await GeoKitSnapshotService.capture(
                viewport: currentViewport,
                size: size,
                styleURI: styleURI
            )
            guard !Task.isCancelled else { return }
            guard snapshotCacheKey(size: size) == cacheKey else { return }
            if let image {
                snapshot = image
                lastCacheKey = cacheKey
            }
        }
    }

    private func snapshotCacheKey(size: CGSize) -> String {
        let camera = viewport.camera
        let center = camera?.center
        let lat = center.map { String(format: "%.5f", $0.latitude) } ?? "nil"
        let lon = center.map { String(format: "%.5f", $0.longitude) } ?? "nil"
        let zoom = camera?.zoom.map { String(format: "%.2f", $0) } ?? "nil"
        let bearing = camera?.bearing.map { String(format: "%.1f", $0) } ?? "0"
        let pitch = camera?.pitch.map { String(format: "%.1f", $0) } ?? "0"
        let w = Int(size.width.rounded())
        let h = Int(size.height.rounded())
        return "\(request.contentID)|\(lat),\(lon)|z\(zoom)|b\(bearing)|p\(pitch)|\(w)x\(h)"
    }
}

private extension MapPin {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
