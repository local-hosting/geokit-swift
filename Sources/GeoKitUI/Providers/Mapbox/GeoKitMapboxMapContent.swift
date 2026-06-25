import CoreLocation
import GeoKitContract
import MapboxMaps
import SwiftUI

/// Mapbox-backed map content for placeholder, snapshot, and live phases.
struct GeoKitMapboxMapContent: View {
    let request: MapContentRequest

    @State private var viewport: Viewport = .idle
    @State private var collapsedSnapshot: UIImage?
    @State private var zoomLevel: Float = 12
    @State private var currentZoom: CGFloat = 12
    @State private var isPlusEnabled = true
    @State private var isMinusEnabled = true
    @State private var liveCameraState: CameraState?
    @State private var selectedPinId: UUID?

    var body: some View {
        phaseContent
            .onAppear {
                seedViewportIfNeeded()
            }
            .onChange(of: request.mapProviderId) { _, _ in
                resetForProviderChange()
            }
            .onChange(of: request.cameraFrame) { _, frame in
                guard let frame else { return }
                viewport = GeoKitMapViewport.from(frame)
            }
    }


    private func resetForProviderChange() {
        viewport = .idle
        collapsedSnapshot = nil
        selectedPinId = nil
        seedViewportIfNeeded()
    }

    private func seedViewportIfNeeded() {
        guard case .idle = viewport else { return }
        applyCameraFrame(request.cameraFrame)
    }

    private func applyCameraFrame(_ frame: MapCameraFrame?) {
        if let frame {
            viewport = GeoKitMapViewport.from(frame)
        } else {
            viewport = GeoKitMapViewport.initial(
                coordinates: request.pins.map(\.coordinate),
                preferredZoom: request.preferredZoom
            )
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch request.phase {
        case .placeholder:
            placeholderContent
        case .snapshot:
            GeoKitCollapsedSnapshotView(
                request: request,
                viewport: $viewport,
                snapshot: $collapsedSnapshot
            )
        case .live:
            GeoKitMapSurface(
                request: request,
                viewport: $viewport,
                zoomLevel: $zoomLevel,
                currentZoom: $currentZoom,
                isPlusEnabled: $isPlusEnabled,
                isMinusEnabled: $isMinusEnabled,
                liveCameraState: $liveCameraState,
                selectedPinId: selectedPinId,
                onPinTap: { pin, _ in selectedPinId = pin.id },
                onPinInteractionBegan: {},
                frozenSnapshot: collapsedSnapshot
            )
        }
    }

    private var placeholderContent: some View {
        ZStack {
            GeoKitMapTheme.placeholderBackground
            Text(request.title)
                .font(GeoKitMapTheme.placeholderTitleFont)
                .foregroundStyle(.secondary)
        }
    }
}

private extension MapPin {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
