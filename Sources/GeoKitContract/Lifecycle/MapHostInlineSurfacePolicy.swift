import CoreGraphics
import Foundation

/// Provider-neutral rules for when a host-owned inline map surface mounts, transitions, or passes through live tiles.
public enum MapHostInlineSurfacePolicy {
    /// Root hoisted host owns the one live GeoKit surface during expand/collapse hero morph.
    public static func rootHostOwnsLiveSurface(
        usesLocalLiveSlice: Bool,
        usesExternalLiveHost: Bool,
        isExpandedOverlay: Bool,
        isExpandLiveHandoff: Bool = false
    ) -> Bool {
        guard usesLocalLiveSlice, usesExternalLiveHost, !isExpandedOverlay else { return false }
        guard !isExpandLiveHandoff else { return false }
        return false
    }

    /// Expanded hero overlay keeps a transparent hole once live tiles exist so the root host is visible.
    public static func showsTransparentRootLivePassThrough(
        isExpandedOverlay: Bool,
        isMapRendered: Bool,
        rootHostOwnsLiveSurface: Bool,
        isCollapsing: Bool = false,
        isCollapseLiveHandoff: Bool = false
    ) -> Bool {
        if rootHostOwnsLiveSurface, isMapRendered { return true }
        guard isExpandedOverlay, isMapRendered else { return false }
        if isCollapsing || isCollapseLiveHandoff { return false }
        return true
    }

    /// Inline maps track card transforms every frame — collection swipe is not a GeoKit layout morph.
    public static func isTransitioning(
        usesLocalLiveSlice: Bool,
        isExpanded: Bool,
        isCollapsing: Bool,
        collectionIsTransitioning: Bool
    ) -> Bool {
        guard usesLocalLiveSlice, !isExpanded else {
            return collectionIsTransitioning || isCollapsing
        }
        return isCollapsing
    }

    public static func paintsInlinePeekSnapshot(
        usesLocalLiveSlice: Bool,
        usesExternalLiveHost: Bool,
        isExpanded: Bool,
        isFocused: Bool,
        isVisiblePeek: Bool
    ) -> Bool {
        guard usesExternalLiveHost, !isExpanded else { return false }
        guard isVisiblePeek, !isFocused else { return false }
        guard usesLocalLiveSlice || isVisiblePeek else { return false }
        return true
    }

    public static func keepsInlineLiveMapMounted(
        usesLocalLiveSlice: Bool,
        usesExternalLiveHost: Bool,
        isExpanded: Bool,
        isExpandedOverlay: Bool,
        isFocused: Bool,
        isVisiblePeek: Bool = false,
        isLiveCard: Bool,
        mediaKeepAlive: Bool,
        isMapRendered: Bool,
        collectionExpanded: Bool,
        isCollapsing: Bool,
        isHeroFrameMorphing: Bool,
        collectionIsTransitioning: Bool,
        isCollapseLiveHandoff: Bool = false,
        isExpandLiveHandoff: Bool = false,
        cardDragOffset: CGFloat
    ) -> Bool {
        guard usesLocalLiveSlice, usesExternalLiveHost, !isExpanded else { return false }
        if isCollapsing { return false }
        if isVisiblePeek, !isFocused { return false }
        let rootOwns = rootHostOwnsLiveSurface(
            usesLocalLiveSlice: usesLocalLiveSlice,
            usesExternalLiveHost: usesExternalLiveHost,
            isExpandedOverlay: isExpandedOverlay,
            isExpandLiveHandoff: isExpandLiveHandoff
        )
        if isMapRendered, isFocused || isLiveCard || mediaKeepAlive {
            guard !rootOwns else { return false }
            return true
        }
        guard !rootOwns else { return false }
        if isFocused || isLiveCard || mediaKeepAlive { return true }
        guard isMapRendered else { return false }
        return collectionIsTransitioning || abs(cardDragOffset) > 1
    }
}
