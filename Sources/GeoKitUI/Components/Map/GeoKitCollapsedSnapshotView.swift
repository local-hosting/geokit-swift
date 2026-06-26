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
                GeoKitMapTheme.placeholderBackground
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
            .onChange(of: request.id) { _, _ in
                lastCacheKey = nil
                refreshSnapshot(size: size)
            }
            .onChange(of: request.mapProviderId) { _, _ in
                lastCacheKey = nil
                snapshot = nil
                refreshSnapshot(size: size)
            }
            .onChange(of: request.snapshotPriority) { _, _ in
                refreshSnapshot(size: size)
            }
        }
        .clipped()
        .preference(key: GeoKitLiveRenderingKey.self, value: false)
        .preference(key: GeoKitMapRenderedKey.self, value: snapshot != nil)
    }

    private func refreshSnapshot(size: CGSize) {
        var resolvedViewport = viewport
        if case .idle = resolvedViewport {
            if let frame = request.cameraFrame {
                resolvedViewport = GeoKitMapViewport.from(frame)
            } else {
                resolvedViewport = GeoKitMapViewport.initial(
                    coordinates: request.pins.map(\.coordinate),
                    preferredZoom: request.preferredZoom
                )
            }
            viewport = resolvedViewport
        }

        let cacheKey = snapshotCacheKey(for: resolvedViewport, size: size)
        guard MapSnapshotRefreshPlan.shouldRefresh(
            layoutSize: size,
            cacheKey: cacheKey,
            lastCacheKey: lastCacheKey,
            hasSnapshot: snapshot != nil
        ) else { return }

        refreshTask?.cancel()
        refreshTask = Task {
            let styleURI = request.mapStyleURI
            let image = await MapSnapshotCaptureExecutor.captureWithRetry {
                await GeoKitSnapshotService.capture(
                    viewport: resolvedViewport,
                    size: size,
                    styleURI: styleURI,
                    priority: request.snapshotPriority
                )
            }
            guard !Task.isCancelled else { return }
            guard snapshotCacheKey(for: resolvedViewport, size: size) == cacheKey else { return }
            if let image {
                snapshot = image
                lastCacheKey = cacheKey
            }
        }
    }

    private func snapshotCacheKey(for viewport: Viewport, size: CGSize) -> String {
        let camera = viewport.camera
        let center = camera?.center
        let lat = center.map { String(format: "%.5f", $0.latitude) } ?? "nil"
        let lon = center.map { String(format: "%.5f", $0.longitude) } ?? "nil"
        let zoom = camera?.zoom.map { String(format: "%.2f", $0) } ?? "nil"
        let bearing = camera?.bearing.map { String(format: "%.1f", $0) } ?? "0"
        let pitch = camera?.pitch.map { String(format: "%.1f", $0) } ?? "0"
        let w = Int(size.width.rounded())
        let h = Int(size.height.rounded())
        let provider = request.mapProviderId?.rawValue ?? "default"
        return "\(request.id)|\(provider)|\(lat),\(lon)|z\(zoom)|b\(bearing)|p\(pitch)|\(w)x\(h)"
    }
}

private extension MapPin {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
