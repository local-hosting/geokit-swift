#if os(iOS)
import GeoKitContract
import SwiftUI
import UIKit

/// Card map slot: static peek image for fan/back cards; live map clipped inside the active top or expanded slot.
public struct GeoKitMapCardSlot<Card: GeoKitLiveMapCard & ObservableObject>: View {
    @ObservedObject public var card: Card
    @ObservedObject public var cameraStore: MapCameraStore
    public let mapProviderId: MapProviderId
    public let presentationContext: MapCardMediaPresentationContext
    public let peekSnapshot: UIImage?
    public let onLiveMountEndedWithoutSnapshot: () -> Void
    public var liveCrossFadeDuration: TimeInterval = GeoKitMapCrossFadeConstants.baseDuration
    public var loadingAccessibilityIdentifier: String?
    public var fanLoadingAccessibilityIdentifier: String?
    /// When true (default for Accord stacks), a single external host paints the live map —
    /// this slot renders a transparent hole so the host shows through; fan slots still show static peeks.
    public var externalLiveMapHost: Bool = true

    @Environment(\.geokitAnimationSpeed) private var animationSpeed
    @State private var liveSnapshotCoversLive = false
    @State private var snapshotVisibleForHost = false
    @State private var hasLockedLivePainted = false

    public init(
        card: Card,
        cameraStore: MapCameraStore,
        mapProviderId: MapProviderId,
        presentationContext: MapCardMediaPresentationContext,
        peekSnapshot: UIImage?,
        onLiveMountEndedWithoutSnapshot: @escaping () -> Void,
        liveCrossFadeDuration: TimeInterval = GeoKitMapCrossFadeConstants.baseDuration,
        loadingAccessibilityIdentifier: String? = nil,
        fanLoadingAccessibilityIdentifier: String? = nil,
        externalLiveMapHost: Bool = true
    ) {
        self.card = card
        self.cameraStore = cameraStore
        self.mapProviderId = mapProviderId
        self.presentationContext = presentationContext
        self.peekSnapshot = peekSnapshot
        self.onLiveMountEndedWithoutSnapshot = onLiveMountEndedWithoutSnapshot
        self.liveCrossFadeDuration = liveCrossFadeDuration
        self.loadingAccessibilityIdentifier = loadingAccessibilityIdentifier
        self.fanLoadingAccessibilityIdentifier = fanLoadingAccessibilityIdentifier
        self.externalLiveMapHost = externalLiveMapHost
    }

    /// The active live slot defers to the external host — render a transparent hole, no in-card live map.
    private var rendersExternalHostHole: Bool {
        externalLiveMapHost && MapCardMediaPresentationPolicy.allowsLiveMount(presentationContext)
    }

    private var showsLiveMap: Bool {
        MapCardMediaPresentationPolicy.showsLiveMap(presentationContext)
    }

    private var showsPaintedLiveMap: Bool {
        showsLiveMap && presentationContext.isMapRendered
    }

    private var liveMapVisible: Bool {
        MapCardMediaPresentationPolicy.liveMapVisible(presentationContext)
    }

    private var mapIsTransitioning: Bool {
        MapCardMediaPresentationPolicy.mapIsTransitioning(presentationContext)
    }

    private var shouldShowLoading: Bool {
        if peekSnapshot != nil { return false }
        return MapCardMediaPresentationPolicy.shouldShowLoadingOverlay(presentationContext)
    }

    private var showsBlankPlaceholder: Bool {
        if presentationContext.isExpandedOverlaySlot { return false }
        return !shouldShowLoading && peekSnapshot == nil && !liveMapVisible
    }

    private var keepsSnapshotVisible: Bool {
        guard peekSnapshot != nil else { return false }
        if hasLockedLivePainted, !mapIsTransitioning { return false }
        if rendersExternalHostHole {
            return !showsPaintedLiveMap
        }
        return liveSnapshotCoversLive || !showsPaintedLiveMap
    }

    private var snapshotCrossfadeDuration: TimeInterval {
        GeoKitMapCrossFadeConstants.scaledDuration(
            animationSpeed: animationSpeed,
            base: liveCrossFadeDuration
        )
    }

    @ViewBuilder
    private func snapshotImage(_ image: UIImage) -> some View {
        GeoKitSnapshotImageFill(image: image, alignment: .center)
    }

    @ViewBuilder
    private func snapshotCrossfadeLayer(_ image: UIImage) -> some View {
        snapshotImage(image)
            .opacity(keepsSnapshotVisible ? 1 : 0)
            .animation(.easeInOut(duration: snapshotCrossfadeDuration), value: keepsSnapshotVisible)
            .allowsHitTesting(false)
            .onChange(of: keepsSnapshotVisible) { wasVisible, isVisible in
                syncSnapshotVisibleForHost(wasVisible: wasVisible, isVisible: isVisible)
            }
            .onAppear {
                snapshotVisibleForHost = keepsSnapshotVisible
                if showsPaintedLiveMap {
                    hasLockedLivePainted = true
                }
            }
            .onChange(of: showsPaintedLiveMap) { _, painted in
                if painted {
                    hasLockedLivePainted = true
                } else if mapIsTransitioning {
                    hasLockedLivePainted = false
                }
            }
    }

    private func syncSnapshotVisibleForHost(wasVisible: Bool, isVisible: Bool) {
        if isVisible {
            snapshotVisibleForHost = true
            return
        }
        guard wasVisible else {
            snapshotVisibleForHost = false
            return
        }
        snapshotVisibleForHost = true
        let duration = snapshotCrossfadeDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if !keepsSnapshotVisible {
                snapshotVisibleForHost = false
            }
        }
    }

    public var body: some View {
        if rendersExternalHostHole {
            ZStack {
                // External host owns the live map for this slot — keep the media area transparent so it shows through.
                Color.clear
                if let image = peekSnapshot {
                    snapshotCrossfadeLayer(image)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .preference(
                key: GeoKitLiveRenderingKey.self,
                value: showsPaintedLiveMap
            )
            .preference(
                key: GeoKitMapSnapshotVisibleKey.self,
                value: snapshotVisibleForHost
            )
        } else {
            inCardBody
        }
    }

    private var inCardBody: some View {
        ZStack {
            GeoKitMapTheme.placeholderBackground

            if let image = peekSnapshot {
                snapshotCrossfadeLayer(image)
            }

            if showsLiveMap {
                GeoKitInCardLiveMapBody(
                    cameraStore: cameraStore,
                    card: card,
                    isExpanded: presentationContext.isExpandedOverlaySlot,
                    mapProviderId: mapProviderId,
                    mapIsTransitioning: mapIsTransitioning
                )
                .id(card.id)
                .environment(\.geokitTransitionSnapshot, peekSnapshot)
                .onPreferenceChange(GeoKitMapSnapshotCoversLiveKey.self) { coversLive in
                    liveSnapshotCoversLive = coversLive
                }
            }

            Color.clear
                .preference(
                    key: GeoKitLiveRenderingKey.self,
                    value: showsPaintedLiveMap && !liveSnapshotCoversLive
                )
                .preference(
                    key: GeoKitMapSnapshotVisibleKey.self,
                    value: snapshotVisibleForHost
                )

            if showsBlankPlaceholder {
                GeoKitMapTheme.placeholderBackground
            }

            if shouldShowLoading {
                cardMediaLoadingChrome
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onChange(of: showsLiveMap) { wasLive, isLive in
            if wasLive, !isLive, peekSnapshot == nil {
                onLiveMountEndedWithoutSnapshot()
            }
        }
        .onChange(of: showsLiveMap) { _, isLive in
            if !isLive {
                liveSnapshotCoversLive = false
                snapshotVisibleForHost = false
            }
        }
    }

    private var cardMediaLoadingChrome: some View {
        ZStack {
            if peekSnapshot == nil {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(GeoKitMapTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Loading")
        .accessibilityIdentifier(
            presentationContext.isStackCenter
                ? (loadingAccessibilityIdentifier ?? "geokit.card-loading")
                : (fanLoadingAccessibilityIdentifier ?? "geokit.card-loading-fan")
        )
    }
}

#endif
