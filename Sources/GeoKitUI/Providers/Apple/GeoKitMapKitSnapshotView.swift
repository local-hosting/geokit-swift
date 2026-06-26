#if os(iOS)
import CoreLocation
import GeoKitContract
import MapKit
import SwiftUI

struct GeoKitMapKitSnapshotView: View {
    let request: MapContentRequest
    @Binding var position: MapCameraPosition
    @Binding var snapshot: UIImage?
    @State private var lastCacheKey: String?
    @State private var refreshTask: Task<Void, Never>?
    @State private var captureAttemptsExhausted = false

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
                } else if MapSnapshotRefreshPlan.shouldShowFailedCapturePlaceholder(
                    hasSnapshot: false,
                    captureAttemptsExhausted: captureAttemptsExhausted
                ) {
                    failedCapturePlaceholder
                }
            }
            .frame(width: size.width, height: size.height)
            .onAppear { refreshSnapshot(size: size) }
            .onChange(of: size) { _, newSize in refreshSnapshot(size: newSize) }
            .onChange(of: request.id) { _, _ in
                lastCacheKey = nil
                captureAttemptsExhausted = false
                refreshSnapshot(size: size)
            }
            .onChange(of: request.mapProviderId) { _, _ in
                lastCacheKey = nil
                snapshot = nil
                captureAttemptsExhausted = false
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

    private var failedCapturePlaceholder: some View {
        ZStack {
            GeoKitMapTheme.placeholderBackground
            Text(request.title)
                .font(GeoKitMapTheme.placeholderTitleFont)
                .foregroundStyle(.secondary)
        }
    }

    private func refreshSnapshot(size: CGSize) {
        let cacheKey = snapshotCacheKey(size: size)
        guard MapSnapshotRefreshPlan.shouldRefresh(
            layoutSize: size,
            cacheKey: cacheKey,
            lastCacheKey: lastCacheKey,
            hasSnapshot: snapshot != nil
        ) else { return }

        var resolvedPosition = position
        if resolvedPosition == .automatic {
            if let frame = request.cameraFrame {
                resolvedPosition = GeoKitMapKitCamera.from(frame)
            } else {
                resolvedPosition = GeoKitMapKitCamera.initialPosition(
                    coordinates: request.pins.map(\.coordinate),
                    preferredZoom: request.preferredZoom
                )
            }
            position = resolvedPosition
        }

        refreshTask?.cancel()
        captureAttemptsExhausted = false
        refreshTask = Task {
            let mapStyle = GeoKitMapProviderRegistry.apple.mapStyle
            let capturePosition = resolvedPosition
            let image = await MapSnapshotCaptureExecutor.captureWithRetry {
                await GeoKitMapKitSnapshotService.capture(
                    position: capturePosition,
                    request: request,
                    size: size,
                    mapStyle: mapStyle
                )
            }
            guard !Task.isCancelled else { return }
            guard snapshotCacheKey(size: size) == cacheKey else { return }
            if let image {
                snapshot = image
                lastCacheKey = cacheKey
                captureAttemptsExhausted = false
            } else {
                captureAttemptsExhausted = true
            }
        }
    }

    private func snapshotCacheKey(size: CGSize) -> String {
        let w = Int(size.width.rounded())
        let h = Int(size.height.rounded())
        if let camera = position.camera {
            let lat = String(format: "%.5f", camera.centerCoordinate.latitude)
            let lon = String(format: "%.5f", camera.centerCoordinate.longitude)
            let zoom = GeoKitMapKitCamera.zoom(
                fromDistance: camera.distance,
                latitude: camera.centerCoordinate.latitude
            )
            let z = String(format: "%.2f", zoom)
            let b = String(format: "%.1f", camera.heading)
            let p = String(format: "%.1f", camera.pitch)
            return "\(request.id)|apple|\(lat),\(lon)|z\(z)|b\(b)|p\(p)|\(w)x\(h)"
        }
        return "\(request.id)|apple|\(w)x\(h)"
    }
}

enum GeoKitMapKitSnapshotService {
    static func capture(
        position: MapCameraPosition,
        request: MapContentRequest,
        size: CGSize,
        mapStyle: AppleMapsProviderConfig.MapStyle
    ) async -> UIImage? {
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: size) else { return nil }
        guard let mapCamera = mkMapCamera(from: position, request: request) else { return nil }

        return await withCheckedContinuation { continuation in
            let options = MKMapSnapshotter.Options()
            options.camera = mapCamera
            options.size = size
            options.scale = UITraitCollection.current.displayScale
            options.mapType = mapStyle.snapshotMapType

            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.start { snapshot, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: snapshot?.image)
            }
        }
    }

    private static func mkMapCamera(from position: MapCameraPosition, request: MapContentRequest) -> MKMapCamera? {
        if let camera = position.camera {
            return MKMapCamera(
                lookingAtCenter: camera.centerCoordinate,
                fromDistance: camera.distance,
                pitch: camera.pitch,
                heading: camera.heading
            )
        } else {
            let coordinates = request.pins.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            guard let center = GeoKitMapKitCamera.centerCoordinate(from: coordinates) ?? coordinates.first else {
                return nil
            }
            let distance = GeoKitMapKitCamera.distanceMeters(forZoom: request.preferredZoom, latitude: center.latitude)
            return MKMapCamera(
                lookingAtCenter: center,
                fromDistance: distance,
                pitch: GeoKitMapKitCamera.collapsedPitch,
                heading: 0
            )
        }
    }
}

private extension AppleMapsProviderConfig.MapStyle {
    var snapshotMapType: MKMapType {
        switch self {
        case .standard:
            return .standard
        case .imagery:
            return .satellite
        case .hybrid:
            return .hybrid
        }
    }
}

private extension GeoKitContract.MapPin {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
#endif
