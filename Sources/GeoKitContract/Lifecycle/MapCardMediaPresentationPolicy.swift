import CardMediaContract
import CoreGraphics
import Foundation

public typealias MapCardMediaPresentationContext = CardMediaPresentationContext

public extension CardMediaPresentationContext {
    var isMapRendered: Bool { isLiveContentRendered }

    init(
        isStackCenter: Bool,
        isStackOneBehind: Bool,
        collectionExpanded: Bool,
        isExpandedOverlaySlot: Bool,
        cardIsTransitioning: Bool,
        cardIsCollapsing: Bool,
        isLiveEnabled: Bool,
        isMapRendered: Bool,
        hasActiveSnapshot: Bool,
        isCenteredInStack: Bool
    ) {
        self.init(
            isStackCenter: isStackCenter,
            isStackOneBehind: isStackOneBehind,
            collectionExpanded: collectionExpanded,
            isExpandedOverlaySlot: isExpandedOverlaySlot,
            cardIsTransitioning: cardIsTransitioning,
            cardIsCollapsing: cardIsCollapsing,
            isLiveEnabled: isLiveEnabled,
            isLiveContentRendered: isMapRendered,
            hasActiveSnapshot: hasActiveSnapshot,
            isCenteredInStack: isCenteredInStack
        )
    }
}

public enum MapCardMediaPresentationPolicy {
    public static func allowsLiveMount(_ context: MapCardMediaPresentationContext) -> Bool {
        CardMediaPresentationPolicy.allowsLiveMount(context)
    }

    public static func isLiveDataEnabled(
        liveCardID: String?,
        warmLiveCardID: String? = nil,
        cardID: String,
        allowsLiveMount: Bool
    ) -> Bool {
        CardMediaPresentationPolicy.isLiveDataEnabled(
            liveCardID: liveCardID,
            warmLiveCardID: warmLiveCardID,
            cardID: cardID,
            allowsLiveMount: allowsLiveMount
        )
    }

    public static func showsLiveMap(_ context: MapCardMediaPresentationContext) -> Bool {
        CardMediaPresentationPolicy.showsLive(context)
    }

    public static func mapIsTransitioning(_ context: MapCardMediaPresentationContext) -> Bool {
        CardMediaPresentationPolicy.mediaIsTransitioning(context)
    }

    public static func liveMapVisible(_ context: MapCardMediaPresentationContext) -> Bool {
        CardMediaPresentationPolicy.liveVisible(context)
    }

    public static func shouldShowLoadingOverlay(_ context: MapCardMediaPresentationContext) -> Bool {
        CardMediaPresentationPolicy.shouldShowLoadingOverlay(context)
    }

    public static func reportsMediaSurfaceFrame(_ context: MapCardMediaPresentationContext) -> Bool {
        CardMediaPresentationPolicy.reportsMediaSurfaceFrame(context)
    }

    public static func snapshotLoadAllowed(
        isExpandedOverlaySlot: Bool,
        isSnapshotBootstrapping: Bool,
        mediaLoadAllowed: Bool,
        isStackCenter: Bool,
        isStackOneBehind: Bool,
        hasActiveSnapshot: Bool
    ) -> Bool {
        CardMediaPresentationPolicy.snapshotLoadAllowed(
            isExpandedOverlaySlot: isExpandedOverlaySlot,
            isSnapshotBootstrapping: isSnapshotBootstrapping,
            mediaLoadAllowed: mediaLoadAllowed,
            isStackCenter: isStackCenter,
            isStackOneBehind: isStackOneBehind,
            hasActiveSnapshot: hasActiveSnapshot
        )
    }

    public static func usesTransparentExternalHostBackdrop(
        externalLiveMapHost: Bool,
        showsPaintedLiveMap: Bool = false
    ) -> Bool {
        CardMediaPresentationPolicy.usesTransparentExternalHostBackdrop(
            externalLiveHost: externalLiveMapHost,
            showsPaintedLive: showsPaintedLiveMap
        )
    }
}

public enum MapLiveSurfaceFrameResolver {
    public static func mediaFrame(fullCardFrame: CGRect, mediaSurfaceFooterInset: CGFloat = 0) -> CGRect {
        CardLiveSurfaceFrameResolver.mediaFrame(
            fullCardFrame: fullCardFrame,
            mediaSurfaceFooterInset: mediaSurfaceFooterInset
        )
    }

    public static func resolve(
        reportedFrame: CGRect,
        collapsedCardFrame: CGRect,
        mediaSurfaceFooterInset: CGFloat = 0
    ) -> CGRect {
        CardLiveSurfaceFrameResolver.resolve(
            reportedFrame: reportedFrame,
            collapsedCardFrame: collapsedCardFrame,
            mediaSurfaceFooterInset: mediaSurfaceFooterInset
        )
    }

    public static func isValidHostFrame(_ frame: CGRect) -> Bool {
        CardLiveSurfaceFrameResolver.isValidHostFrame(frame)
    }
}

public enum MapLiveCardSelectionPolicy {
    public static func liveCardID(
        centerCardID: String,
        centerHasUsableSnapshot: Bool,
        centerMapRendered: Bool
    ) -> String? {
        CardLiveSelectionPolicy.liveCardID(
            centerCardID: centerCardID,
            centerHasUsableSnapshot: centerHasUsableSnapshot,
            centerLiveContentRendered: centerMapRendered
        )
    }
}
