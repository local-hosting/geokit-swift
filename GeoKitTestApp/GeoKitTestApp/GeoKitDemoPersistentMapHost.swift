#if os(iOS)
import AccordDesignSystem
import GeoKit
import GeoKitContract
import GeoKitUI
import SwiftUI

/// One Mapbox surface per active card — resizes with the reported media frame; never remounts on expand/collapse.
struct GeoKitDemoPersistentMapHost: View {
    @ObservedObject var cameraStore: MapCameraStore
    @ObservedObject var card: GeoKitDemoCard
    let frame: CGRect
    let cornerRadius: CGFloat
    let collapsedReferenceFrame: CGRect
    let isExpanded: Bool
    let mapProviderId: MapProviderId
    let mapIsTransitioning: Bool

    @State private var acceptsPinSelectionUpdates = false

    private var centerFrame: MapLiveSurfaceCenterFrame {
        MapLiveSurfaceCenterFrame(globalFrame: frame)
    }

    var body: some View {
        GeometryReader { root in
            let origin = root.frame(in: .global).origin
            GeoKitDemoPersistentMapBody(
                cameraStore: cameraStore,
                card: card,
                isExpanded: isExpanded,
                mapProviderId: mapProviderId,
                mapIsTransitioning: mapIsTransitioning,
                acceptsPinSelectionUpdates: $acceptsPinSelectionUpdates
            )
            .id(card.id)
            .geokitCenterAnchoredGlobalFrame(
                centerFrame,
                localOrigin: origin,
                cornerRadius: cornerRadius
            )
            .allowsHitTesting(true)
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live map")
        .accessibilityIdentifier("geokit-test-app.live-map")
    }
}

/// Holds Mapbox state across expand/collapse frame resizes for the same card id.
private struct GeoKitDemoPersistentMapBody: View {
    @ObservedObject var cameraStore: MapCameraStore
    @ObservedObject var card: GeoKitDemoCard
    let isExpanded: Bool
    let mapProviderId: MapProviderId
    let mapIsTransitioning: Bool
    @Binding var acceptsPinSelectionUpdates: Bool

    private func transitionSnapshot(for provider: MapProviderId) -> UIImage? {
        guard card.hasUsableSnapshot(
            for: provider,
            cameraFrame: cameraStore.frame(for: card.id)
        ) else { return nil }
        return card.frozenSnapshot(for: provider)
    }

    var body: some View {
        Group {
            if let mapContent = GeoKitRuntime.mapContent {
                mapContent(
                    card.mapRequest(
                        isExpanded: isExpanded,
                        allowsLiveMount: true,
                        isCenterSlot: !isExpanded,
                        mapProviderId: mapProviderId,
                        cameraFrame: cameraStore.frame(for: card.id)
                    )
                )
                .environment(
                    \.geokitTransitionSnapshot,
                    transitionSnapshot(for: mapProviderId)
                )
                .environment(\.geokitMapIsTransitioning, mapIsTransitioning)
                .onAppear { acceptsPinSelectionUpdates = true }
                .onDisappear { acceptsPinSelectionUpdates = false }
                .onPreferenceChange(GeoKitMapCameraFrameKey.self) { cameraFrame in
                    guard let cameraFrame, !mapIsTransitioning else { return }
                    cameraStore.setFrame(cameraFrame, for: card.id)
                }
                .onPreferenceChange(GeoKitSelectedPinIdKey.self) { pinId in
                    guard acceptsPinSelectionUpdates, let pinId else { return }
                    card.selectedPinId = pinId
                }
                .onPreferenceChange(GeoKitMapRenderedKey.self) { rendered in
                    if rendered { card.setMapRendered(true, for: mapProviderId) }
                }
            }
        }
    }
}
#endif
