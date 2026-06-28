#if os(iOS)
import GeoKitContract
import SwiftUI

/// Live map content clipped to the card media slot — expand/collapse animates with ``AXCard`` chrome.
public struct GeoKitInCardLiveMapBody<Card: GeoKitLiveMapCard & ObservableObject>: View {
    @ObservedObject public var cameraStore: MapCameraStore
    @ObservedObject public var card: Card
    public let isExpanded: Bool
    public let mapProviderId: MapProviderId
    public let mapIsTransitioning: Bool

    @State private var acceptsPinSelectionUpdates = false

    public init(
        cameraStore: MapCameraStore,
        card: Card,
        isExpanded: Bool,
        mapProviderId: MapProviderId,
        mapIsTransitioning: Bool
    ) {
        self.cameraStore = cameraStore
        self.card = card
        self.isExpanded = isExpanded
        self.mapProviderId = mapProviderId
        self.mapIsTransitioning = mapIsTransitioning
    }

    public var body: some View {
        Group {
            if let mapContent = GeoKitRuntime.mapContent {
                mapContent(
                    card.liveMapRequest(
                        isExpanded: isExpanded,
                        mapProviderId: mapProviderId,
                        cameraFrame: cameraStore.frame(for: card.id)
                    )
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
#endif
