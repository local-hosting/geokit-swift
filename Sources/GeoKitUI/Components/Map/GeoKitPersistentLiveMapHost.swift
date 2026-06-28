#if os(iOS)
import GeoKitContract
import SwiftUI

/// Deprecated — mount live maps inside ``GeoKitMapCardSlot`` so expand/collapse stays in the card view tree.
@available(*, deprecated, message: "Use GeoKitMapCardSlot with live map clipped inside the card slot.")
public struct GeoKitPersistentLiveMapHost<Card: GeoKitLiveMapCard & ObservableObject>: View {
    @ObservedObject public var cameraStore: MapCameraStore
    @ObservedObject public var card: Card
    public let frame: CGRect
    public let cornerRadius: CGFloat
    public let isExpanded: Bool
    public let mapProviderId: MapProviderId
    public let mapIsTransitioning: Bool
    public var accessibilityIdentifierPrefix: String = "geokit.live-map"

    @State private var liveMapHasContent = false

    public init(
        cameraStore: MapCameraStore,
        card: Card,
        frame: CGRect,
        cornerRadius: CGFloat,
        isExpanded: Bool,
        mapProviderId: MapProviderId,
        mapIsTransitioning: Bool,
        accessibilityIdentifierPrefix: String = "geokit.live-map"
    ) {
        self.cameraStore = cameraStore
        self.card = card
        self.frame = frame
        self.cornerRadius = cornerRadius
        self.isExpanded = isExpanded
        self.mapProviderId = mapProviderId
        self.mapIsTransitioning = mapIsTransitioning
        self.accessibilityIdentifierPrefix = accessibilityIdentifierPrefix
    }

    private var centerFrame: MapLiveSurfaceCenterFrame {
        MapLiveSurfaceCenterFrame(globalFrame: frame)
    }

    public var body: some View {
        GeometryReader { root in
            let origin = root.frame(in: .global).origin
            GeoKitInCardLiveMapBody(
                cameraStore: cameraStore,
                card: card,
                isExpanded: isExpanded,
                mapProviderId: mapProviderId,
                mapIsTransitioning: mapIsTransitioning
            )
            .id(card.id)
            .environment(
                \.geokitMapSurfaceReady,
                MapLiveSurfaceFrameResolver.isValidHostFrame(frame)
            )
            .geokitCenterAnchoredGlobalFrame(
                centerFrame,
                localOrigin: origin,
                cornerRadius: cornerRadius
            )
            .onPreferenceChange(GeoKitMapRenderedKey.self) { rendered in
                liveMapHasContent = rendered
            }
            .allowsHitTesting(true)
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live map")
        .accessibilityIdentifier(
            liveMapHasContent
                ? "\(accessibilityIdentifierPrefix)-rendered"
                : accessibilityIdentifierPrefix
        )
    }
}
#endif
