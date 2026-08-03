import CoreGraphics
import Foundation

public enum MapHostInlineSurfacePolicy {
    public static func rootHostOwnsLiveSurface(
        usesInlineLiveSlice: Bool,
        usesExternalLiveHost: Bool,
        isExpandedOverlay: Bool,
        isExpandLiveHandoff: Bool = false
    ) -> Bool {
        guard usesInlineLiveSlice, usesExternalLiveHost, !isExpandedOverlay else { return false }
        guard !isExpandLiveHandoff else { return false }
        return false
    }

    public static func showsTransparentRootLivePassThrough(
        isExpandedOverlay: Bool,
        isMapRendered: Bool,
        rootHostOwnsLiveSurface: Bool,
        isCollapsing: Bool = false,
        isCollapseLiveHandoff: Bool = false,
        isHeroFrameMorphing: Bool = false,
        isExpandLiveHandoff: Bool = false,
        isTransitioning: Bool = false,
        collapsePosterMatchesLiveCamera: Bool = false
    ) -> Bool {
        if keepsExpandedOverlaySnapshotDuringMorph(
            isExpandedOverlay: isExpandedOverlay,
            isCollapsing: isCollapsing,
            isCollapseLiveHandoff: isCollapseLiveHandoff,
            isHeroFrameMorphing: isHeroFrameMorphing,
            isExpandLiveHandoff: isExpandLiveHandoff,
            isTransitioning: isTransitioning,
            isMapRendered: isMapRendered,
            collapsePosterMatchesLiveCamera: collapsePosterMatchesLiveCamera
        ) {
            return false
        }
        guard isExpandedOverlay else { return false }
        if rootHostOwnsLiveSurface, isMapRendered { return true }
        return isMapRendered
    }

    public static func keepsExpandedOverlaySnapshotDuringMorph(
        isExpandedOverlay: Bool,
        isCollapsing: Bool,
        isCollapseLiveHandoff: Bool,
        isHeroFrameMorphing: Bool,
        isExpandLiveHandoff: Bool,
        isTransitioning: Bool,
        isMapRendered: Bool = false,
        collapsePosterMatchesLiveCamera: Bool = false
    ) -> Bool {
        if isCollapseLiveHandoff { return true }
        if isCollapsing {
            guard isExpandedOverlay else { return false }
            if collapsePosterMatchesLiveCamera { return true }
            return !isMapRendered
        }
        guard isExpandedOverlay else { return false }
        return isHeroFrameMorphing || isExpandLiveHandoff || isTransitioning
    }

    /// Hoisted root host: true for expand/collapse hero morph so GeoKit can latch a live-frame freeze.
    /// Do **not** pass card-drag ``mapLayoutTransitioning`` here — drag offset also flips that flag and would
    /// trigger an expensive live ``captureSnapshot`` on every swipe.
    public static func hoistedGeoKitIsTransitioning(
        isHeroMorphing: Bool,
        isMapRendered: Bool,
        mapIsTransitioning: Bool
    ) -> Bool {
        if isHeroMorphing { return true }
        guard !isMapRendered else { return false }
        return mapIsTransitioning
    }

    /// Inline maps track card transforms every frame — collection swipe is not a GeoKit layout morph.
    public static func isTransitioning(
        usesInlineLiveSlice: Bool,
        isExpanded: Bool,
        isCollapsing: Bool,
        collectionIsTransitioning: Bool
    ) -> Bool {
        guard usesInlineLiveSlice, !isExpanded else {
            return collectionIsTransitioning || isCollapsing
        }
        return isCollapsing
    }

    public static func paintsInlinePeekSnapshot(
        usesInlineLiveSlice: Bool,
        usesExternalLiveHost: Bool,
        isExpanded: Bool,
        isFocused: Bool,
        isVisiblePeek: Bool
    ) -> Bool {
        guard usesExternalLiveHost, !isExpanded else { return false }
        guard isVisiblePeek, !isFocused else { return false }
        guard usesInlineLiveSlice || isVisiblePeek else { return false }
        return true
    }

    public static func keepsInlineLiveMapMounted(
        usesInlineLiveSlice: Bool,
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
        _ = usesInlineLiveSlice
        _ = mediaKeepAlive
        _ = isMapRendered
        _ = collectionExpanded
        _ = collectionIsTransitioning
        _ = cardDragOffset
        _ = isVisiblePeek

        // Expanded hero and morph handoffs use the root host — never duplicate inline Metal.
        if isExpandedOverlay || isExpanded { return false }
        if isCollapsing || isCollapseLiveHandoff { return false }
        if isExpandLiveHandoff || isHeroFrameMorphing { return false }

        // Collapsed stack/deck: paint live GeoKit in the focused card hole instead of an
        // endless static-poster spinner while the session map warms off-screen.
        guard usesExternalLiveHost, isFocused, isLiveCard else { return false }
        return true
    }
}
