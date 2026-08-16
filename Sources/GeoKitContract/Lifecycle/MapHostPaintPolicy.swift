import CoreGraphics
import Foundation

/// Layout-agnostic host composition inputs — callers map collection UI (deck, carousel, etc.) to these flags.

/// Resolved hoisted media-hole branch for host-owned map cards.
public enum MapHoistedHoleContent: Sendable, Equatable {
    case transparentPassThrough
    case peekSnapshot
    case peekLoading
    case liveClear
    case snapshotPoster
    case runtimeBootstrap
    case visiblePeekClear
    case darkPlate
}

/// Inline static bitmap layer flags for host-owned map cards.
public struct MapInlineStaticLayer: Sendable, Equatable {
    public let isVisible: Bool
    public let showsDarkPlate: Bool
    public let showsSnapshot: Bool
    public let showsLoading: Bool

    public init(isVisible: Bool, showsDarkPlate: Bool, showsSnapshot: Bool, showsLoading: Bool) {
        self.isVisible = isVisible
        self.showsDarkPlate = showsDarkPlate
        self.showsSnapshot = showsSnapshot
        self.showsLoading = showsLoading
    }
}

/// Provider-neutral map paint resolution for host-owned inline surfaces and hoisted holes.
///
/// Card chrome (focus index, hero morph, collection layout) supplies inputs; GeoKit decides
/// static vs live vs bootstrap vs pass-through so only one map engine mounts at a time.
public enum MapHostPaintPolicy {
    /// Whether the card hole may bootstrap a second inline GeoKit engine while a root host owns live.
    public static func paintsInCardSnapshotBootstrap(
        isExpandedOverlay: Bool,
        isFocused: Bool,
        showsLiveHole: Bool,
        isLiveCard: Bool,
        hasCoverPoster: Bool,
        usesInlineLiveSlice: Bool = false,
        isCollapsing: Bool = false,
        isCollapseLiveHandoff: Bool = false,
        isMapRendered: Bool = false,
        isVisiblePeek: Bool = false,
        mediaLoadAllowed: Bool = true
    ) -> Bool {
        // Never mount a second GeoKit/Mapbox engine for bootstrap.
        // Collapsed = static poster; expanded live mounts once via the root host.
        _ = isExpandedOverlay
        _ = isFocused
        _ = showsLiveHole
        _ = isLiveCard
        _ = hasCoverPoster
        _ = usesInlineLiveSlice
        _ = isCollapsing
        _ = isCollapseLiveHandoff
        _ = isMapRendered
        _ = isVisiblePeek
        _ = mediaLoadAllowed
        return false
    }

    public static func paintsStaticMapboxBitmap(
        usesExternalLiveHost: Bool,
        isExpandedOverlay: Bool,
        collectionExpanded: Bool,
        isMapRendered: Bool,
        isLiveCard: Bool,
        isFocused: Bool,
        isVisiblePeek: Bool,
        paintsVisibleInlineLiveMap: Bool,
        paintsInlinePeekSnapshot: Bool,
        showsTransparentRootLivePassThrough: Bool
    ) -> Bool {
        if showsTransparentRootLivePassThrough { return false }
        if isExpandedOverlay, isMapRendered { return false }
        if usesExternalLiveHost,
           collectionExpanded,
           !isExpandedOverlay,
           !isVisiblePeek,
           isMapRendered {
            return false
        }
        if usesExternalLiveHost {
            if !isMapRendered, !isLiveCard { return true }
            return !paintsVisibleInlineLiveMap
        }
        return paintsInlinePeekSnapshot || (isFocused && !paintsVisibleInlineLiveMap)
    }

    public static func paintsHoistedLiveHole(
        usesInlineLiveSlice: Bool,
        isVisiblePeek: Bool,
        isFocused: Bool,
        paintsInlinePeekSnapshot: Bool,
        rootHostOwnsLiveSurface: Bool,
        paintsInlineLiveMap: Bool
    ) -> Bool {
        if usesInlineLiveSlice, isVisiblePeek, !isFocused { return false }
        if usesInlineLiveSlice, paintsInlinePeekSnapshot { return false }
        if usesInlineLiveSlice, isFocused, !paintsInlineLiveMap { return false }
        return rootHostOwnsLiveSurface || !paintsInlineLiveMap
    }

    public static func hoistedHoleContent(
        showsTransparentRootLivePassThrough: Bool,
        paintsInlinePeekSnapshot: Bool,
        hasPeekSnapshot: Bool,
        hasGeneralCover: Bool,
        mediaLoadAllowed: Bool,
        isMapRendered: Bool,
        paintsVisibleInlineLiveMap: Bool,
        paintsInCardSnapshotBootstrap: Bool,
        isVisiblePeek: Bool,
        isExpandedOverlay: Bool,
        usesExternalLiveHost: Bool
    ) -> MapHoistedHoleContent {
        if showsTransparentRootLivePassThrough { return .transparentPassThrough }
        if usesExternalLiveHost, isExpandedOverlay, !isMapRendered { return .transparentPassThrough }
        if paintsInlinePeekSnapshot {
            if hasPeekSnapshot { return .peekSnapshot }
            if mediaLoadAllowed || paintsInlinePeekSnapshot { return .peekLoading }
        }
        if isMapRendered, paintsVisibleInlineLiveMap { return .liveClear }
        if hasPeekSnapshot || hasGeneralCover { return .snapshotPoster }
        if paintsInCardSnapshotBootstrap { return .runtimeBootstrap }
        if isVisiblePeek { return .visiblePeekClear }
        return .darkPlate
    }

    public static func inlineStaticLayer(
        paintsStaticMapboxBitmap: Bool,
        hasPeekSnapshot: Bool,
        hasGeneralCover: Bool,
        paintsInlinePeekSnapshot: Bool,
        isVisiblePeek: Bool,
        mediaLoadAllowed: Bool
    ) -> MapInlineStaticLayer {
        guard paintsStaticMapboxBitmap else {
            return MapInlineStaticLayer(
                isVisible: false,
                showsDarkPlate: false,
                showsSnapshot: false,
                showsLoading: false
            )
        }
        let hasPoster = hasPeekSnapshot || hasGeneralCover
        let showsSnapshot = hasPoster
        let showsDarkPlate = !hasPoster && !paintsInlinePeekSnapshot && !isVisiblePeek
        let showsLoading = !hasPoster
            && (mediaLoadAllowed || paintsInlinePeekSnapshot || isVisiblePeek)
        return MapInlineStaticLayer(
            isVisible: true,
            showsDarkPlate: showsDarkPlate,
            showsSnapshot: showsSnapshot,
            showsLoading: showsLoading
        )
    }
}
