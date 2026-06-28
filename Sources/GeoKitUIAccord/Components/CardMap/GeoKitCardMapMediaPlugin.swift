#if os(iOS)
import AccordDesignSystem
import CardMediaContract
import CoreGraphics
import GeoKitContract
import GeoKitUI
import SwiftUI

/// Map media plugin — driven by ``AXCardMediaLoadCoordinator`` events; no direct collection observation.
@MainActor
public final class GeoKitCardMapMediaPlugin<Card: GeoKitLiveMapCard & AXCardItem>: AXCardMediaLoadPlugin {
    public let mediaKind: AXCardMediaKind = .map

    private weak var coordinator: GeoKitCardMapCoordinator<Card>?
    private weak var collection: AXCardCollectionModel<Card>?
    private var skipSnapshotCapture: () -> Bool = { false }

    public init() {}

    public func bind(
        coordinator: GeoKitCardMapCoordinator<Card>,
        collection: AXCardCollectionModel<Card>,
        skipSnapshotCapture: @escaping () -> Bool = { false }
    ) {
        self.coordinator = coordinator
        self.collection = collection
        self.skipSnapshotCapture = skipSnapshotCapture
    }

    public func unbind() {
        collection = nil
        skipSnapshotCapture = { false }
    }

    public func collectionDidAppear(session: AXCardMediaLoadSession) {
        coordinator?.bootstrapCenterMedia(session: session, skipSnapshotCapture: skipSnapshotCapture())
    }

    public func centerIndexChanged(session: AXCardMediaLoadSession) {
        coordinator?.handleCenterIndexChange(session: session)
    }

    public func stackPageChanged(session: AXCardMediaLoadSession) {
        coordinator?.handleCollectionIdentityChange(session: session)
    }

    public func expandedChanged(expanded: Bool, session: AXCardMediaLoadSession) {
        coordinator?.handleExpandedChange(expanded: expanded, session: session)
    }

    public func collapseFinished(wasCollapsing: Bool, session: AXCardMediaLoadSession) {
        coordinator?.handleCollapseFinished(wasCollapsing: wasCollapsing, session: session)
    }

    public func containerWidthChanged(session: AXCardMediaLoadSession) {
        coordinator?.handleContainerWidthChange(session: session)
    }

    public func collapsedFrameChanged(session: AXCardMediaLoadSession) {
        coordinator?.handleCollapsedFrameChange(session: session)
    }

    public func cardDragChanged(session: AXCardMediaLoadSession, dragOffset: CGFloat) {
        coordinator?.handleCardDragChanged(session: session, dragOffset: dragOffset, collection: collection)
    }

    public func cardDragEnded(session: AXCardMediaLoadSession, isTransitioning: Bool) {
        coordinator?.handleCardDragCancelled(isTransitioning: isTransitioning)
    }

    public func prepareExpansion(context: CardMediaExpansionContext, onReady: @escaping () -> Void) -> Bool {
        guard let coordinator, let collection else { return false }
        guard let card = collection.cards.first(where: { $0.id == context.cardID }) as? Card else {
            return false
        }
        coordinator.prepareCardExpansion(
            card: card,
            mapSize: context.layoutSize,
            cameraFrame: coordinator.cameraStore.frame(for: card.id),
            onReady: onReady
        )
        return true
    }

    public func collectionWillDisappear() {
        unbind()
    }
    public func demotedCardChoreographyEnded(session: AXCardMediaLoadSession) {
        coordinator?.handleDemotedCardChoreographyEnded(session: session)
    }

}
#endif
