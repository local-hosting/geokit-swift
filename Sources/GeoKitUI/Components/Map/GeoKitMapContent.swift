#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

import GeoKitContract
import SwiftUI

/// Top-level map view — routes to registered map providers (Mapbox via GeoKitUIMapbox, Apple via GeoKitUI).
public struct GeoKitMapContent: View {
    let request: MapContentRequest

    public init(request: MapContentRequest) {
        self.request = request
    }

    public var body: some View {
        Group {
            if let content = GeoKitMapProviderContentRegistry.content(for: request) {
                content
                    .id(GeoKitMapProviderRegistry.resolve(for: request))
            } else {
                missingProviderFallback
            }
        }
        .allowsHitTesting(request.mapAcceptsUserInteraction)
        .preference(
            key: GeoKitMapInteractiveGesturesKey.self,
            value: request.mapAcceptsUserInteraction
        )
#if canImport(UIKit)
        .geokitIsolatePlatformMapAccessibility()
#endif
    }

    private var missingProviderFallback: some View {
        ZStack {
            GeoKitMapTheme.placeholderBackground
            Text("Map provider is not registered")
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
    let selectedPinId: UUID?

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
        mapProviderId: MapProviderId? = nil,
        selectedPinId: UUID? = nil
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
        self.selectedPinId = selectedPinId
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
                mapProviderId: mapProviderId,
                selectedPinId: selectedPinId
            )
        )
        .environment(\.geokitMapSurfaceReady, lifecycle.isSurfaceReady)
        .environment(\.geokitMapIsTransitioning, lifecycle.isTransitioning)
    }
}
#endif
