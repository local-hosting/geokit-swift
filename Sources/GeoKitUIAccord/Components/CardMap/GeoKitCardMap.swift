#if os(iOS)
import AccordDesignSystem
import CardMediaContract
import GeoKitContract
import GeoKitUI
import SwiftUI
import UIKit

/// Drop-in map content for any Accord card collection (``AX.Stack``, ``AX.Deck``, ``AX.Scroller``, ``AX.CarouselCollection``, ``CardExpanded``).
public struct GeoKitCardMap<Card: GeoKitLiveMapCard & AXCardItem>: View {
    @ObservedObject public var card: Card
    @EnvironmentObject private var coordinator: GeoKitCardMapCoordinator<Card>

    public var loadingAccessibilityIdentifier: String?
    public var fanLoadingAccessibilityIdentifier: String?
    public var cardAccessibilityIdentifierPrefix: String?

    public init(
        card: Card,
        loadingAccessibilityIdentifier: String? = nil,
        fanLoadingAccessibilityIdentifier: String? = nil,
        cardAccessibilityIdentifierPrefix: String? = nil
    ) {
        self.card = card
        self.loadingAccessibilityIdentifier = loadingAccessibilityIdentifier
        self.fanLoadingAccessibilityIdentifier = fanLoadingAccessibilityIdentifier
        self.cardAccessibilityIdentifierPrefix = cardAccessibilityIdentifierPrefix
    }

    public var body: some View {
        GeoKitCardMapSlotReader { slotEnvironment in
            GeoKitCardMapBody(
                card: card,
                coordinator: coordinator,
                slotEnvironment: slotEnvironment,
                loadingAccessibilityIdentifier: loadingAccessibilityIdentifier,
                fanLoadingAccessibilityIdentifier: fanLoadingAccessibilityIdentifier,
                cardAccessibilityIdentifierPrefix: cardAccessibilityIdentifierPrefix
            )
        }
    }
}

private struct GeoKitCardMapSlotReader<Content: View>: View {
    @Environment(\.axCardIsCentered) private var isCentered
    @Environment(\.axCardStackOffset) private var stackOffset
    @Environment(\.axCardCollectionExpanded) private var collectionExpanded
    @Environment(\.axCardIsTransitioning) private var isTransitioning
    @Environment(\.axCardIsCollapsing) private var isCollapsing
    @Environment(\.axCardIsExpandedOverlay) private var isExpandedOverlay
    @Environment(\.axCardMediaKeepAlive) private var mediaKeepAlive
    @Environment(\.axCardTransitionBaseSize) private var transitionBaseSize
    @Environment(\.axCardTransitionTargetSize) private var transitionTargetSize

    let content: (CardMediaSlotEnvironment) -> Content

    var body: some View {
        content(
            CardMediaSlotEnvironment(
                isCentered: isCentered,
                stackOffset: stackOffset,
                collectionExpanded: collectionExpanded,
                isTransitioning: isTransitioning,
                isCollapsing: isCollapsing,
                isExpandedOverlay: isExpandedOverlay,
                mediaKeepAlive: mediaKeepAlive,
                transitionBaseSize: transitionBaseSize,
                transitionTargetSize: transitionTargetSize
            )
        )
    }
}

private struct GeoKitCardMapBody<Card: GeoKitLiveMapCard & AXCardItem>: View {
    @ObservedObject var card: Card
    @ObservedObject var coordinator: GeoKitCardMapCoordinator<Card>
    let slotEnvironment: CardMediaSlotEnvironment
    var loadingAccessibilityIdentifier: String?
    var fanLoadingAccessibilityIdentifier: String?
    var cardAccessibilityIdentifierPrefix: String?

    private var role: GeoKitCardSlotRole {
        CardMediaSlotPresentation.slotRole(from: slotEnvironment)
    }

    private var peekSnapshot: UIImage? {
        card.frozenSnapshot(for: coordinator.provider)
    }

    private var displayedPeekSnapshot: UIImage? {
        if role == .center, coordinator.mediaStore.isSnapshotBootstrapping {
            return nil
        }
        if coordinator.mediaStore.warmLiveCardID == card.id {
            return nil
        }
        if CardMediaSlotPresentation.paintsStaticSnapshot(role: role, environment: slotEnvironment) {
            return peekSnapshot
        }
        return nil
    }

    private var presentationContext: MapCardMediaPresentationContext {
        CardMediaSlotPresentation.presentationContext(
            environment: slotEnvironment,
            cardID: card.id,
            liveCardID: coordinator.mediaStore.liveCardID,
            warmLiveCardID: coordinator.mediaStore.warmLiveCardID,
            isLiveContentRendered: card.isMapRendered(for: coordinator.provider),
            hasActiveSnapshot: peekSnapshot != nil
        )
    }

    private var geokitTransitionFullTargetSize: CGSize {
        guard slotEnvironment.isTransitioning || slotEnvironment.isCollapsing else { return .zero }
        let screen = UIScreen.main.bounds.size
        return CGSize(width: screen.width, height: screen.height)
    }

    private var isFocusedSlot: Bool {
        role == .center
    }

    private var cardLiveRendering: Bool {
        guard MapCardMediaPresentationPolicy.showsLiveMap(presentationContext) else { return false }
        return card.isMapRendered(for: coordinator.provider)
    }

    var body: some View {
        GeoKitMapCardSlot(
            card: card,
            cameraStore: coordinator.cameraStore,
            mapProviderId: coordinator.provider,
            presentationContext: presentationContext,
            peekSnapshot: displayedPeekSnapshot,
            onLiveMountEndedWithoutSnapshot: {
                card.setMapRendered(false, for: coordinator.provider)
            },
            loadingAccessibilityIdentifier: loadingAccessibilityIdentifier,
            fanLoadingAccessibilityIdentifier: fanLoadingAccessibilityIdentifier,
            externalLiveMapHost: CardMediaSlotPresentation.usesExternalLiveHost(environment: slotEnvironment)
        )
        .axReportsCardMediaSurfaceFrame(
            cardID: card.id,
            active: CardMediaSlotPresentation.reportsLiveSurfaceFramePreference(
                environment: slotEnvironment,
                role: role
            )
        )
        .environment(\.geokitCardTransitionBaseSize, slotEnvironment.transitionBaseSize)
        .environment(\.geokitCardTransitionTargetSize, slotEnvironment.transitionTargetSize)
        .environment(\.geokitCardTransitionFullTargetSize, geokitTransitionFullTargetSize)
        .preference(
            key: AXCardPeekMediaPaintedKey.self,
            value: displayedPeekSnapshot != nil
                || (MapCardMediaPresentationPolicy.showsLiveMap(presentationContext)
                    && card.isMapRendered(for: coordinator.provider))
        )
        .preference(
            key: AXCardLiveRenderingKey.self,
            value: cardLiveRendering
        )
        .allowsHitTesting(slotEnvironment.isExpandedOverlay)
        .accessibilityIdentifier(cardAccessibilityIdentifier)
    }

    private var cardAccessibilityIdentifier: String {
        let prefix = cardAccessibilityIdentifierPrefix ?? "geokit.card"
        if isFocusedSlot,
           peekSnapshot != nil || (
               MapCardMediaPresentationPolicy.showsLiveMap(presentationContext)
                   && card.isMapRendered(for: coordinator.provider)
           ) {
            return "\(prefix)-media-ready"
        }
        return "\(prefix)-\(card.id)"
    }
}
#endif
