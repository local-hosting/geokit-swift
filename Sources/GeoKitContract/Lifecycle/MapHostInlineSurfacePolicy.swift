import CoreGraphics
import Foundation

/// Layout-agnostic host composition inputs — callers map collection UI (deck, carousel, etc.) to these flags.

/// Provider-neutral rules for when a host-owned inline map surface mounts, transitions, or passes through live tiles.
public enum MapHostInlineSurfacePolicy {
    /// Root hoisted host owns the one live GeoKit surface during expand/collapse hero morph.
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
        // Video-style: never mount inline Mapbox Metal in-card.
        // Collapsed stays static poster (swipe-safe). Expanded live paints from the root
        // ``AXMapMediaHost`` only — mounting both inline + root remount-fights GeoKit.
        _ = usesInlineLiveSlice
        _ = usesExternalLiveHost
        _ = isExpanded
        _ = isExpandedOverlay
        _ = isFocused
        _ = isVisiblePeek
        _ = isLiveCard
        _ = mediaKeepAlive
        _ = isMapRendered
        _ = collectionExpanded
        _ = isCollapsing
        _ = isHeroFrameMorphing
        _ = collectionIsTransitioning
        _ = isCollapseLiveHandoff
        _ = isExpandLiveHandoff
        _ = cardDragOffset
        return false
    }
}
