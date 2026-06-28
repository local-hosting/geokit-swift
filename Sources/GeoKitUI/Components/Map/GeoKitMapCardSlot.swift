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
    public let mapSize: CGSize
    public let mapMediaGeneration: UInt
    public let peekSnapshotLoadAllowed: Bool
    public let cameraFrame: MapCameraFrame?
    public let mapMediaController: GeoKitCardMapMediaController
    public let onLoadingChanged: (Bool) -> Void
    public let onLiveMountEndedWithoutSnapshot: () -> Void
    public var liveCrossFadeDuration: TimeInterval = 0.3
    public var loadingAccessibilityIdentifier: String?
    public var fanLoadingAccessibilityIdentifier: String?
    /// When true (default for Accord stacks), a single external host paints the live map —
    /// this slot renders a transparent hole so the host shows through; fan slots still show static peeks.
    public var externalLiveMapHost: Bool = true

    @State private var liveSnapshotCoversLive = false

    public init(
        card: Card,
        cameraStore: MapCameraStore,
        mapProviderId: MapProviderId,
        presentationContext: MapCardMediaPresentationContext,
        peekSnapshot: UIImage?,
        mapSize: CGSize,
        mapMediaGeneration: UInt,
        peekSnapshotLoadAllowed: Bool,
        cameraFrame: MapCameraFrame?,
        mapMediaController: GeoKitCardMapMediaController = .shared,
        onLoadingChanged: @escaping (Bool) -> Void,
        onLiveMountEndedWithoutSnapshot: @escaping () -> Void,
        liveCrossFadeDuration: TimeInterval = 0.3,
        loadingAccessibilityIdentifier: String? = nil,
        fanLoadingAccessibilityIdentifier: String? = nil,
        externalLiveMapHost: Bool = true
    ) {
        self.card = card
        self.cameraStore = cameraStore
        self.mapProviderId = mapProviderId
        self.presentationContext = presentationContext
        self.peekSnapshot = peekSnapshot
        self.mapSize = mapSize
        self.mapMediaGeneration = mapMediaGeneration
        self.peekSnapshotLoadAllowed = peekSnapshotLoadAllowed
        self.cameraFrame = cameraFrame
        self.mapMediaController = mapMediaController
        self.onLoadingChanged = onLoadingChanged
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
        return liveSnapshotCoversLive || !showsPaintedLiveMap
    }

    @ViewBuilder
    private func snapshotImage(_ image: UIImage) -> some View {
        GeoKitSnapshotImageFill(image: image, alignment: .center)
    }

    public var body: some View {
        if rendersExternalHostHole {
            // External host owns the live map for this slot — keep the media area transparent so it shows through.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .preference(
                    key: GeoKitLiveRenderingKey.self,
                    value: presentationContext.isMapRendered
                )
        } else {
            inCardBody
        }
    }

    private var inCardBody: some View {
        ZStack {
            GeoKitMapTheme.placeholderBackground

            if let image = peekSnapshot {
                snapshotImage(image)
                    .opacity(keepsSnapshotVisible ? 1 : 0)
                    .animation(.easeInOut(duration: liveCrossFadeDuration), value: keepsSnapshotVisible)
                    .allowsHitTesting(false)
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

            if showsBlankPlaceholder {
                GeoKitMapTheme.placeholderBackground
            }

            if shouldShowLoading {
                cardMediaLoadingChrome
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .geokitSelfManagedMapMedia(
            card: card,
            isCentered: presentationContext.isStackCenter,
            provider: mapProviderId,
            mapSize: mapSize,
            generation: mapMediaGeneration,
            loadAllowed: peekSnapshotLoadAllowed,
            cameraFrame: cameraFrame,
            controller: mapMediaController,
            onLoadingChanged: onLoadingChanged
        )
        .onChange(of: showsLiveMap) { wasLive, isLive in
            if wasLive, !isLive, peekSnapshot == nil {
                onLiveMountEndedWithoutSnapshot()
            }
        }
        .onChange(of: showsLiveMap) { _, isLive in
            if !isLive {
                liveSnapshotCoversLive = false
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

@available(*, deprecated, renamed: "GeoKitMapCardSlot")
public typealias GeoKitExternalHostMapCardSlot = GeoKitMapCardSlot
#endif
