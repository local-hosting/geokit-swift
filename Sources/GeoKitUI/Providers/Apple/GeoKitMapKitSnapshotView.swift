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
            .onChange(of: request.id) { _, _ in
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

        if case .automatic = position {
            position = GeoKitMapKitCamera.initialPosition(
                coordinates: request.pins.map(\.coordinate),
                preferredZoom: request.preferredZoom
            )
        }

        let cacheKey = snapshotCacheKey(size: size)
        if cacheKey == lastCacheKey, snapshot != nil { return }

        refreshTask?.cancel()
        refreshTask = Task {
            let image = await GeoKitMapKitSnapshotService.capture(
                request: request,
                size: size,
                mapStyle: GeoKitMapProviderRegistry.apple.mapStyle
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
        let w = Int(size.width.rounded())
        let h = Int(size.height.rounded())
        return "\(request.id)|apple|\(w)x\(h)"
    }
}

enum GeoKitMapKitSnapshotService {
    static func capture(
        request: MapContentRequest,
        size: CGSize,
        mapStyle: AppleMapsProviderConfig.MapStyle
    ) async -> UIImage? {
        guard size.width >= GeoKitMapLayout.minMapSize,
              size.height >= GeoKitMapLayout.minMapSize
        else { return nil }

        let coordinates = request.pins.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        guard let center = GeoKitMapKitCamera.centerCoordinate(from: coordinates) ?? coordinates.first else {
            return nil
        }
        let distance = GeoKitMapKitCamera.distanceMeters(forZoom: request.preferredZoom, latitude: center.latitude)
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: distance * 1.5,
            longitudinalMeters: distance * 1.5
        )

        return await withCheckedContinuation { continuation in
            let options = MKMapSnapshotter.Options()
            options.region = region
            options.size = size
            options.scale = UITraitCollection.current.displayScale
            options.mapType = mapStyle.snapshotMapType

            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.start { snapshot, _ in
                continuation.resume(returning: snapshot?.image)
            }
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
