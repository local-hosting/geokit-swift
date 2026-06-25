#if os(iOS)
import CoreLocation
import GeoKitContract
import MapKit
import SwiftUI

struct GeoKitMapKitMapContent: View {
    let request: MapContentRequest

    @State private var position: MapCameraPosition = .automatic
    @State private var collapsedSnapshot: UIImage?
    @State private var zoomLevel: Float = 12
    @State private var selectedPinId: UUID?

    var body: some View {
        phaseContent
            .onAppear {
                seedPositionIfNeeded()
            }
            .onChange(of: request.mapProviderId) { _, _ in
                resetForProviderChange()
            }
            .onChange(of: request.cameraFrame) { _, frame in
                guard let frame else { return }
                position = GeoKitMapKitCamera.from(frame)
            }
    }


    private func resetForProviderChange() {
        position = .automatic
        collapsedSnapshot = nil
        selectedPinId = nil
        seedPositionIfNeeded()
    }

    private func seedPositionIfNeeded() {
        guard case .automatic = position else { return }
        applyCameraFrame(request.cameraFrame)
    }

    private func applyCameraFrame(_ frame: MapCameraFrame?) {
        if let frame {
            position = GeoKitMapKitCamera.from(frame)
        } else {
            position = GeoKitMapKitCamera.initialPosition(
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
            GeoKitMapKitSnapshotView(
                request: request,
                position: $position,
                snapshot: $collapsedSnapshot
            )
        case .live:
            GeoKitMapKitMapSurface(
                request: request,
                position: $position,
                zoomLevel: $zoomLevel,
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

private extension GeoKitContract.MapPin {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
#endif
