import CoreLocation
import GeoKitContract
import MapboxMaps
import SwiftUI

/// Top-level map view for placeholder, snapshot, and live Mapbox rendering phases.
public struct GeoKitMapContent: View {
    let request: MapContentRequest

    @State private var viewport: Viewport = .idle
    @State private var collapsedSnapshot: UIImage?
    @State private var zoomLevel: Float = 12
    @State private var currentZoom: CGFloat = 12
    @State private var isPlusEnabled = true
    @State private var isMinusEnabled = true
    @State private var liveCameraState: CameraState?
    @State private var selectedPinId: UUID?

    public init(request: MapContentRequest) {
        self.request = request
    }

    public var body: some View {
        Group {
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
        .onAppear {
            if case .idle = viewport {
                viewport = GeoKitMapViewport.initial(
                    coordinates: request.pins.map(\.coordinate),
                    preferredZoom: request.preferredZoom
                )
            }
        }
        .accessibilityIdentifier("geokit-map-content-\(request.contentID)")
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

/// Host-driven map content that resolves placeholder / snapshot / live from stack policy.
public struct GeoKitMapContentWithLifecycle: View {
    let contentID: String
    let policy: MapStagePolicy
    let lifecycle: MapLifecycleState
    let isExpanded: Bool
    let title: String
    let mapStyleURI: String
    let preferredZoom: Double
    let pins: [MapPin]
    let showUserPuck: Bool

    public init(
        contentID: String,
        policy: MapStagePolicy,
        lifecycle: MapLifecycleState,
        isExpanded: Bool,
        title: String = "",
        mapStyleURI: String = "",
        preferredZoom: Double = 12,
        pins: [MapPin] = [],
        showUserPuck: Bool = false
    ) {
        self.contentID = contentID
        self.policy = policy
        self.lifecycle = lifecycle
        self.isExpanded = isExpanded
        self.title = title
        self.mapStyleURI = mapStyleURI
        self.preferredZoom = preferredZoom
        self.pins = pins
        self.showUserPuck = showUserPuck
    }

    public var body: some View {
        GeoKitMapContent(
            request: MapContentRequestBuilder.make(
                contentID: contentID,
                policy: policy,
                lifecycle: lifecycle,
                isExpanded: isExpanded,
                title: title,
                mapStyleURI: mapStyleURI,
                preferredZoom: preferredZoom,
                pins: pins,
                showUserPuck: showUserPuck
            )
        )
        .environment(\.geokitMapSurfaceReady, lifecycle.isSurfaceReady)
        .environment(\.geokitMapIsTransitioning, lifecycle.isTransitioning)
    }
}

