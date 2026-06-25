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
                if case .automatic = position {
                    position = GeoKitMapKitCamera.initialPosition(
                        coordinates: request.pins.map(\.coordinate),
                        preferredZoom: request.preferredZoom
                    )
                }
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
