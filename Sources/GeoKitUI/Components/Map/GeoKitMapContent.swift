import GeoKitContract
import SwiftUI

/// Top-level map view — routes to Mapbox or Apple Maps based on provider registry / request override.
public struct GeoKitMapContent: View {
    let request: MapContentRequest

    public init(request: MapContentRequest) {
        self.request = request
    }

    public var body: some View {
        Group {
            switch GeoKitMapProviderRegistry.resolve(for: request) {
            case .mapbox:
                GeoKitMapboxMapContent(request: request)
                    .id(MapProviderId.mapbox)
            case .apple:
                #if os(iOS)
                GeoKitMapKitMapContent(request: request)
                    .id(MapProviderId.apple)
                #else
                unsupportedProviderFallback
                #endif
            }
        }
        .allowsHitTesting(request.mapAcceptsUserInteraction)
        .preference(
            key: GeoKitMapInteractiveGesturesKey.self,
            value: request.mapAcceptsUserInteraction
        )
        .accessibilityIdentifier("geokit-map-content-\(request.id)")
    }

    private var unsupportedProviderFallback: some View {
        ZStack {
            GeoKitMapTheme.placeholderBackground
            Text("Apple Maps is only available on iOS")
                .font(GeoKitMapTheme.placeholderTitleFont)
                .foregroundStyle(.secondary)
        }
    }
}

/// Host-driven map content that resolves placeholder / snapshot / live from stack policy.
public struct GeoKitMapContentWithLifecycle: View {
    let id: String
    let policy: MapStagePolicy
    let lifecycle: MapLifecycleState
    let isExpanded: Bool
    let title: String
    let mapStyleURI: String
    let preferredZoom: Double
    let pins: [MapPin]
    let showUserPuck: Bool
    let mapProviderId: MapProviderId?

    public init(
        id: String,
        policy: MapStagePolicy,
        lifecycle: MapLifecycleState,
        isExpanded: Bool,
        title: String = "",
        mapStyleURI: String = "",
        preferredZoom: Double = 12,
        pins: [MapPin] = [],
        showUserPuck: Bool = false,
        mapProviderId: MapProviderId? = nil
    ) {
        self.id = id
        self.policy = policy
        self.lifecycle = lifecycle
        self.isExpanded = isExpanded
        self.title = title
        self.mapStyleURI = mapStyleURI
        self.preferredZoom = preferredZoom
        self.pins = pins
        self.showUserPuck = showUserPuck
        self.mapProviderId = mapProviderId
    }

    public var body: some View {
        GeoKitMapContent(
            request: MapContentRequestBuilder.make(
                id: id,
                policy: policy,
                lifecycle: lifecycle,
                isExpanded: isExpanded,
                title: title,
                mapStyleURI: mapStyleURI,
                preferredZoom: preferredZoom,
                pins: pins,
                showUserPuck: showUserPuck,
                mapProviderId: mapProviderId
            )
        )
        .environment(\.geokitMapSurfaceReady, lifecycle.isSurfaceReady)
        .environment(\.geokitMapIsTransitioning, lifecycle.isTransitioning)
    }
}
