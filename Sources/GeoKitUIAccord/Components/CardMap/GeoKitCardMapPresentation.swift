#if os(iOS)
import AccordDesignSystem
import CoreGraphics
import GeoKitContract
import GeoKitUI
import UIKit

enum GeoKitCardMapPresentation {
    @MainActor
    static func slotRole(from stackContext: AXCardStackContext) -> GeoKitCardSlotRole {
        GeoKitCardSlotRoleResolver.role(
            isCentered: stackContext.isCentered,
            stackOffset: stackContext.stackOffset,
            collectionExpanded: stackContext.collectionExpanded,
            isCollapsing: stackContext.isCollapsing,
            isExpandedOverlay: stackContext.isExpandedOverlay
        )
    }

    static func isStackCenter(role: GeoKitCardSlotRole) -> Bool {
        role == .center
    }

    /// Peek-window slot (behind or beside center) that should paint a static snapshot in-card.
    static func isFanPeekSlot(stackContext: AXCardStackContext) -> Bool {
        guard !stackContext.isExpandedOverlay else { return false }
        let distance = abs(stackContext.stackOffset)
        guard distance > 0 else { return false }
        return distance <= CGFloat(GeoKitMapCardStageConstants.peekRadius)
    }

    static func reportsLiveFrame(
        stackContext: AXCardStackContext,
        role: GeoKitCardSlotRole
    ) -> Bool {
        if stackContext.isExpandedOverlay { return true }
        return role == .center
            && !stackContext.collectionExpanded
            && !stackContext.isCollapsing
            && !stackContext.isTransitioning
    }

    @MainActor
    static func presentationContext(
        stackContext: AXCardStackContext,
        card: some GeoKitLiveMapCard,
        liveCardID: String?,
        warmLiveCardID: String?,
        mapProviderId: MapProviderId,
        peekSnapshot: UIImage?
    ) -> MapCardMediaPresentationContext {
        let role = slotRole(from: stackContext)
        let isStackCenter = isStackCenter(role: role)
        let isStackOneBehind = stackContext.stackOffset == 1 && !stackContext.collectionExpanded
        let allowsLiveMount = MapCardMediaPresentationPolicy.allowsLiveMount(
            MapCardMediaPresentationContext(
                isStackCenter: isStackCenter,
                isStackOneBehind: isStackOneBehind,
                collectionExpanded: stackContext.collectionExpanded,
                isExpandedOverlaySlot: stackContext.isExpandedOverlay,
                cardIsTransitioning: stackContext.isTransitioning,
                cardIsCollapsing: stackContext.isCollapsing,
                isLiveEnabled: false,
                isMapRendered: card.isMapRendered(for: mapProviderId),
                hasActiveSnapshot: peekSnapshot != nil,
                isCenteredInStack: stackContext.isCentered
            )
        )
        return MapCardMediaPresentationContext(
            isStackCenter: isStackCenter,
            isStackOneBehind: isStackOneBehind,
            collectionExpanded: stackContext.collectionExpanded,
            isExpandedOverlaySlot: stackContext.isExpandedOverlay,
            cardIsTransitioning: stackContext.isTransitioning,
            cardIsCollapsing: stackContext.isCollapsing,
            isLiveEnabled: MapCardMediaPresentationPolicy.isLiveDataEnabled(
                liveCardID: liveCardID,
                warmLiveCardID: warmLiveCardID,
                cardID: card.id,
                allowsLiveMount: allowsLiveMount
            ),
            isMapRendered: card.isMapRendered(for: mapProviderId),
            hasActiveSnapshot: peekSnapshot != nil,
            isCenteredInStack: stackContext.isCentered
        )
    }

    static func peekSnapshotLoadAllowed(
        stackContext: AXCardStackContext,
        role: GeoKitCardSlotRole,
        isSnapshotBootstrapping: Bool,
        hasSnapshot: Bool
    ) -> Bool {
        MapCardMediaPresentationPolicy.snapshotLoadAllowed(
            isExpandedOverlaySlot: stackContext.isExpandedOverlay,
            isSnapshotBootstrapping: isSnapshotBootstrapping,
            mediaLoadAllowed: stackContext.mediaLoadAllowed,
            isStackCenter: role == .center,
            isStackOneBehind: stackContext.stackOffset == 1 && !stackContext.collectionExpanded,
            hasActiveSnapshot: hasSnapshot
        )
    }
}
#endif
