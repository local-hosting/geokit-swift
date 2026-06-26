#if os(iOS)
import GeoKit
import GeoKitContract
import GeoKitUI
import SwiftUI

/// Live map mounted inside ``AXCard`` media — shares the card clip, footer, and expand/collapse transform.
struct GeoKitDemoInCardLiveMap: View {
    @ObservedObject var cameraStore: MapCameraStore
    @ObservedObject var card: GeoKitDemoCard
    let isExpanded: Bool
    let mapProviderId: MapProviderId
    let mapIsTransitioning: Bool

    @State private var acceptsPinSelectionUpdates = false

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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(
                    \.geokitTransitionSnapshot,
                    card.frozenSnapshot(for: mapProviderId)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live map")
        .accessibilityIdentifier("geokit-test-app.live-map")
    }
}
#endif
