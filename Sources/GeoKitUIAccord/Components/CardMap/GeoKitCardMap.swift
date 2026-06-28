#if os(iOS)
import AccordDesignSystem
import GeoKitContract
import GeoKitUI
import SwiftUI
import UIKit

/// Drop-in map content for ``AX.Stack`` / ``CardExpanded`` card slots.
public struct GeoKitCardMap<Card: GeoKitLiveMapCard & AXCardItem>: View {
    @ObservedObject public var card: Card
    @EnvironmentObject private var coordinator: GeoKitCardMapCoordinator<Card>
    @Environment(\.axCardStackContext) private var stackContext
    @Environment(\.axCardMediaLayoutSize) private var cardMediaLayoutSize

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

    private var role: GeoKitCardSlotRole {
        GeoKitCardMapPresentation.slotRole(from: stackContext)
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
        if stackContext.isExpandedOverlay || role == .center || GeoKitCardMapPresentation.isFanPeekSlot(stackContext: stackContext) {
            return peekSnapshot
        }
        return nil
    }

    private var effectiveMapSize: CGSize {
        let layoutSize = AX.Layout.isValidCardMediaLayoutSize(cardMediaLayoutSize)
            ? cardMediaLayoutSize
            : coordinator.collapsedMapContentSize
        return GeoKitCardMapLayout.mediaMapSize(forCardContentSize: layoutSize)
    }

    private var presentationContext: MapCardMediaPresentationContext {
        GeoKitCardMapPresentation.presentationContext(
            stackContext: stackContext,
            card: card,
            liveCardID: coordinator.mediaStore.liveCardID,
            warmLiveCardID: coordinator.mediaStore.warmLiveCardID,
            mapProviderId: coordinator.provider,
            peekSnapshot: peekSnapshot
        )
    }

    private var peekSnapshotLoadAllowed: Bool {
        GeoKitCardMapPresentation.peekSnapshotLoadAllowed(
            stackContext: stackContext,
            role: role,
            isSnapshotBootstrapping: coordinator.mediaStore.isSnapshotBootstrapping,
            hasSnapshot: card.hasUsableSnapshot(
                for: coordinator.provider,
                cameraFrame: coordinator.cameraStore.frame(for: card.id)
            )
        )
    }

    private var geokitTransitionFullTargetSize: CGSize {
        guard stackContext.isTransitioning || stackContext.isCollapsing else { return .zero }
        let screen = UIScreen.main.bounds.size
        return CGSize(width: screen.width, height: screen.height)
    }

    private var isStackCenter: Bool {
        GeoKitCardMapPresentation.isStackCenter(role: role)
    }

    public var body: some View {
        GeoKitMapCardSlot(
            card: card,
            cameraStore: coordinator.cameraStore,
            mapProviderId: coordinator.provider,
            presentationContext: presentationContext,
            peekSnapshot: displayedPeekSnapshot,
            mapSize: effectiveMapSize,
            mapMediaGeneration: coordinator.mediaStore.mapMediaGeneration,
            peekSnapshotLoadAllowed: peekSnapshotLoadAllowed,
            cameraFrame: coordinator.cameraStore.frame(for: card.id),
            mapMediaController: coordinator.mediaStore.mapMediaController,
            onLoadingChanged: { coordinator.mediaStore.setMapLoading($0, cardID: card.id) },
            onLiveMountEndedWithoutSnapshot: {
                card.setMapRendered(false, for: coordinator.provider)
            },
            loadingAccessibilityIdentifier: loadingAccessibilityIdentifier,
            fanLoadingAccessibilityIdentifier: fanLoadingAccessibilityIdentifier,
            // External host only used for the expanded overlay — collapsed center renders the live map inside the card.
            externalLiveMapHost: stackContext.isExpandedOverlay
        )
        .axReportsCardMediaSurfaceFrame(
            cardID: card.id,
            active: GeoKitCardMapPresentation.reportsLiveFrame(stackContext: stackContext, role: role)
        )
        .environment(\.geokitCardTransitionBaseSize, stackContext.transitionBaseSize)
        .environment(\.geokitCardTransitionTargetSize, stackContext.transitionTargetSize)
        .environment(\.geokitCardTransitionFullTargetSize, geokitTransitionFullTargetSize)
        .preference(
            key: AXCardLiveRenderingKey.self,
            value: MapCardMediaPresentationPolicy.showsLiveMap(presentationContext)
                && card.isMapRendered(for: coordinator.provider)
        )
        .allowsHitTesting(stackContext.isExpandedOverlay)
        .accessibilityIdentifier(cardAccessibilityIdentifier)
    }

    private var cardAccessibilityIdentifier: String {
        let prefix = cardAccessibilityIdentifierPrefix ?? "geokit.card"
        if isStackCenter,
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
