import CoreGraphics
import Foundation

/// Inputs for card map slot presentation — loading overlay, live mount, and surface-frame reporting.
public struct MapCardMediaPresentationContext: Equatable, Sendable {
    public let isStackCenter: Bool
    public let isStackOneBehind: Bool
    public let deckExpanded: Bool
    public let isExpandedOverlaySlot: Bool
    public let cardIsTransitioning: Bool
    public let cardIsCollapsing: Bool
    public let isLiveEnabled: Bool
    public let isMapRendered: Bool
    public let hasActiveSnapshot: Bool
    public let isCenteredInStack: Bool

    public init(
        isStackCenter: Bool,
        isStackOneBehind: Bool,
        deckExpanded: Bool,
        isExpandedOverlaySlot: Bool,
        cardIsTransitioning: Bool,
        cardIsCollapsing: Bool,
        isLiveEnabled: Bool,
        isMapRendered: Bool,
        hasActiveSnapshot: Bool,
        isCenteredInStack: Bool
    ) {
        self.isStackCenter = isStackCenter
        self.isStackOneBehind = isStackOneBehind
        self.deckExpanded = deckExpanded
        self.isExpandedOverlaySlot = isExpandedOverlaySlot
        self.cardIsTransitioning = cardIsTransitioning
        self.cardIsCollapsing = cardIsCollapsing
        self.isLiveEnabled = isLiveEnabled
        self.isMapRendered = isMapRendered
        self.hasActiveSnapshot = hasActiveSnapshot
        self.isCenteredInStack = isCenteredInStack
    }
}

/// Pure presentation rules for one persistent live map under card chrome.
public enum MapCardMediaPresentationPolicy {
    public static func allowsLiveMount(_ context: MapCardMediaPresentationContext) -> Bool {
        if context.deckExpanded {
            return context.isExpandedOverlaySlot
        }
        return context.isStackCenter
    }

    public static func showsLiveMap(_ context: MapCardMediaPresentationContext) -> Bool {
        allowsLiveMount(context) && context.isLiveEnabled
    }

    public static func mapIsTransitioning(_ context: MapCardMediaPresentationContext) -> Bool {
        context.cardIsCollapsing
            || context.cardIsTransitioning
            || (context.isExpandedOverlaySlot
                && !context.isMapRendered
                && !context.cardIsTransitioning)
            || (context.isStackCenter
                && !context.isExpandedOverlaySlot
                && showsLiveMap(context)
                && !context.isMapRendered)
    }

    public static func liveMapVisible(_ context: MapCardMediaPresentationContext) -> Bool {
        (showsLiveMap(context) && context.isMapRendered)
            || (showsLiveMap(context) && mapIsTransitioning(context))
    }

    public static func shouldShowLoadingOverlay(_ context: MapCardMediaPresentationContext) -> Bool {
        if liveMapVisible(context) || context.hasActiveSnapshot { return false }
        if context.cardIsCollapsing { return false }
        if showsLiveMap(context), !context.isMapRendered {
            return false
        }
        return context.isStackCenter || context.isStackOneBehind
    }

    public static func reportsMediaSurfaceFrame(_ context: MapCardMediaPresentationContext) -> Bool {
        guard context.isLiveEnabled else { return false }
        if context.deckExpanded {
            // Only the expanded overlay reports — stack slots share cardID and must not compete.
            if context.isExpandedOverlaySlot { return true }
            return false
        }
        if allowsLiveMount(context) { return true }
        return context.cardIsTransitioning && context.isCenteredInStack
    }

    public static func snapshotLoadAllowed(
        isExpandedOverlaySlot: Bool,
        isSnapshotBootstrapping: Bool,
        mediaLoadAllowed: Bool,
        isStackCenter: Bool,
        isStackOneBehind: Bool,
        hasActiveSnapshot: Bool
    ) -> Bool {
        guard !isExpandedOverlaySlot, !isSnapshotBootstrapping else { return false }
        return (mediaLoadAllowed && !isStackCenter)
            || (isStackCenter && !hasActiveSnapshot)
            || (isStackOneBehind && !hasActiveSnapshot)
    }
}

public enum MapLiveSurfaceFrameResolver {
    public static func resolve(reportedFrame: CGRect, collapsedCardFrame: CGRect) -> CGRect {
        if reportedFrame.width > 1, reportedFrame.height > 1 {
            return reportedFrame
        }
        guard collapsedCardFrame.width > 1, collapsedCardFrame.height > 1 else {
            return .zero
        }
        return collapsedCardFrame
    }

    public static func isValidHostFrame(_ frame: CGRect) -> Bool {
        frame.width > 1 && frame.height > 1
    }
}

public enum MapLiveCardSelectionPolicy {
    /// Center card owns the single live surface; snapshots cross-fade underneath while tiles warm up.
    public static func liveCardID(
        centerCardID: String,
        centerHasUsableSnapshot: Bool,
        centerMapRendered: Bool
    ) -> String? {
        centerCardID
    }
}
