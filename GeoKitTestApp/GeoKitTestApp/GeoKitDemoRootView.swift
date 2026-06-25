import AccordDesignSystem
import GeoKit
import GeoKitContract
import GeoKitUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class GeoKitDemoMapProviderStore: ObservableObject {
    @Published var provider: MapProviderId = .mapbox {
        didSet {
            guard oldValue != provider else { return }
            GeoKitMapProviderRegistry.configure(provider: provider)
            GeoKitMapBootstrap.prepare(provider: provider)
        }
    }
}

struct GeoKitDemoRootView: View {
    @StateObject private var deck = GeoKitDemoDeck()
    @StateObject private var mapProviderStore = GeoKitDemoMapProviderStore()
    @StateObject private var mediaStore = GeoKitDemoMediaStore()
    @Namespace private var cardNamespace

    /// Collapsed stack only — expanded overlay uses full screen + ``AXCloseButton`` top trailing.
    private var showsMapProviderPicker: Bool {
        !deck.isExpanded && !deck.isCollapsing
    }

    private var collapsedMapContentSize: CGSize {
        let measured = deck.collapsedCardFrame.size
        if AX.Layout.isValidCardMediaLayoutSize(measured) {
            return measured
        }
        let containerWidth = deck.containerWidth > 0 ? deck.containerWidth : UIScreen.main.bounds.width
        return AX.StackConstants.resolvedCardSize(
            in: CGSize(width: containerWidth, height: 10_000)
        )
    }

    private var expandedMapContentSize: CGSize {
        UIScreen.main.bounds.size
    }

    var body: some View {
        AXBackdropShell {
            ZStack {
                GeoKitDemoBackdropActivationView()

                cardStackRegion
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        // Top trailing is reserved for the standard close control when expanded.
                        if showsMapProviderPicker {
                            mapProviderHeader
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .axGlassPlacement(.overScene)
        }
        .accessibilityIdentifier("geokit-test-app.root")
    }

    private var cardStackRegion: some View {
        AX.Stack(
            viewModel: deck,
            cardNamespace: cardNamespace,
            stackPadding: AX.StackConstants.defaultPadding,
            onBackCardTap: { _, index in
                // Bring the tapped back card forward (Time Machine peel) using the same
                // stack rotation as the paging dots — not the deck-swipe `switchToCard`,
                // which would break the stack's currentIndex == 0 invariant.
                let count = deck.cards.count
                guard !deck.isExpanded, count > 0 else { return }
                deck.rotateStackToPage((deck.stackPageIndex + index) % count)
            },
            paging: stackPaging
        ) { card, isExpanded in
            GeoKitDemoCardContent(
                card: card,
                isExpanded: isExpanded,
                mapProviderId: mapProviderStore.provider,
                mapContentSize: isExpanded ? expandedMapContentSize : collapsedMapContentSize
            )
        } headerContent: { card in
            AXBadge(title: card.title, subtitle: card.subtitle, placement: .cardFooter)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            mediaStore.bindDeck(deck)
            syncFanSnapshots(force: true)
        }
        .onChange(of: deck.stackPageIndex) { _, _ in
            syncFanSnapshots(debounceMs: 0)
        }
        .onChange(of: deck.cardDragOffset) { _, offset in
            mediaStore.handleIncomingCenterDrag(
                liveDragOffset: offset,
                containerWidth: deck.containerWidth,
                cards: deck.cards,
                centerIndex: 0
            )
        }
        .onChange(of: deck.containerWidth) { _, width in
            if deck.cardDragOffset != 0 {
                mediaStore.handleIncomingCenterDrag(
                    liveDragOffset: deck.cardDragOffset,
                    containerWidth: width,
                    cards: deck.cards,
                    centerIndex: 0
                )
            }
            syncFanSnapshots()
        }
        .onChange(of: mapProviderStore.provider) { _, _ in
            mediaStore.invalidateAllSnapshots(in: deck.cards)
            syncFanSnapshots(force: true)
        }
        .onChange(of: deck.collapsedCardFrame) { _, frame in
            guard AX.Layout.isValidCardMediaLayoutSize(frame.size) else { return }
            guard !deck.isExpanded, !deck.isCollapsing else { return }
            syncFanSnapshots()
        }
        .environmentObject(mediaStore)
    }

    private var stackPaging: AXStackPaging? {
        guard deck.cards.count > 1 else { return nil }
        return AXStackPaging(
            pageCount: deck.cards.count,
            currentIndex: deck.stackPageIndex,
            dotColor: AX.Colors.whiteSmoke,
            canSelectPage: { _ in !deck.isTransitioning },
            onPageSelected: { index in
                if deck.isExpanded {
                    deck.switchToCardWhileExpanded(index: index)
                } else {
                    deck.rotateStackToPage(index)
                }
            }
        )
    }



    private func syncFanSnapshots(force: Bool = false, debounceMs: Int = 120) {
        guard AX.Layout.isValidCardMediaLayoutSize(collapsedMapContentSize) else { return }
        mediaStore.updateMapContentSize(collapsedMapContentSize)
        mediaStore.scheduleBootstrapFanSnapshots(
            cards: deck.cards,
            centerIndex: 0,
            provider: mapProviderStore.provider,
            debounceMs: force ? 0 : debounceMs,
            onMediaReady: { index in
                deck.handleMediaEvent(.mediaReady(kind: .map), at: index)
            }
        )
    }

    private var mapProviderHeader: some View {
        AX.SegmentedControl(
            selection: $mapProviderStore.provider,
            options: MapProviderId.allCases,
            title: { provider in
                switch provider {
                case .mapbox: "Mapbox"
                case .apple: "MapKit"
                }
            },
            horizontalPadding: 0
        )
        .frame(width: 220)
        .frame(maxWidth: .infinity)
        .padding(.top, AX.Layout.spacingS)
        .padding(.bottom, AX.Layout.spacingL)
        .accessibilityIdentifier("geokit-test-app.map-provider-picker")
    }
}

private struct GeoKitDemoBackdropActivationView: View {
    @EnvironmentObject private var backdrop: AXBackdropController

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onAppear { backdrop.showActive() }
    }
}

private struct GeoKitDemoCardContent: View {
    @ObservedObject var card: GeoKitDemoCard
    @EnvironmentObject private var mediaStore: GeoKitDemoMediaStore
    let isExpanded: Bool
    let mapProviderId: MapProviderId
    let mapContentSize: CGSize

    /// Cross-fade between the static snapshot and the freshly-painted live map.
    private static let liveCrossFadeDuration: TimeInterval = 0.3

    @Environment(\.axCardIsCentered) private var isCentered
    @Environment(\.axCardStackOffset) private var stackOffset
    @Environment(\.axCardDeckExpanded) private var deckExpanded
    @Environment(\.axCardIsTransitioning) private var cardIsTransitioning
    @Environment(\.axCardIsCollapsing) private var cardIsCollapsing
    @Environment(\.axCardMediaLoadAllowed) private var mediaLoadAllowed

    private var isStackCenter: Bool {
        isCentered && (!deckExpanded || cardIsCollapsing)
    }

    private var isStackOneBehind: Bool {
        stackOffset == 1 && !deckExpanded
    }

    /// Card behind center while the front card is dragged away — live load starts here.
    private var isPredictedIncomingCenter: Bool {
        isStackOneBehind && mediaStore.isDraggingToNextCard
    }

    private var allowsLiveMount: Bool {
        isExpanded || isStackCenter || isStackOneBehind || isPredictedIncomingCenter
    }

    private var showsLiveMap: Bool {
        guard mediaStore.isLivePreloaded(cardID: card.id) else { return false }
        return allowsLiveMount
    }

    /// Static image stays visible through collapse shrink; live fades in only after paint.
    private var showsSnapshotOverlay: Bool {
        guard card.frozenSnapshot != nil else { return false }
        if cardIsCollapsing { return true }
        if cardIsTransitioning { return true }
        if isExpanded { return false }
        if isStackOneBehind, !isPredictedIncomingCenter { return true }
        return !card.isMapRendered || liveMapOpacity < 1
    }

    private var liveMapOpacity: Double {
        guard showsLiveMap else { return 0 }
        guard card.isMapRendered else { return 0 }
        if cardIsCollapsing, card.frozenSnapshot != nil { return 0 }
        if cardIsTransitioning, !isStackCenter, !isPredictedIncomingCenter { return 0 }
        if isExpanded || isStackCenter || isPredictedIncomingCenter {
            return 1
        }
        return 0
    }

    private var mediaPlaceholderColor: Color {
        if isExpanded || cardIsCollapsing || (isStackCenter && card.isMapRendered) {
            return AX.Colors.blackRussian
        }
        return Color(white: 0.94)
    }

    /// Center card shows a spinner while its static snapshot is captured.
    private var shouldShowLoading: Bool {
        isStackCenter
            && card.frozenSnapshot == nil
            && (mediaStore.isMapLoading(cardID: card.id) || mediaStore.isFanBootstrapping)
    }

    var body: some View {
        ZStack {
            if let image = card.frozenSnapshot {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(showsSnapshotOverlay ? 1 : 0)
                    .animation(.easeInOut(duration: Self.liveCrossFadeDuration), value: showsSnapshotOverlay)
                    .allowsHitTesting(false)
            }

            if showsLiveMap, let mapContent = GeoKitRuntime.mapContent {
                mapContent(
                    card.mapRequest(
                        isExpanded: isExpanded,
                        allowsLiveMount: allowsLiveMount,
                        isCenterSlot: isStackCenter,
                        mapProviderId: mapProviderId,
                        cameraFrame: card.lastCameraFrame
                    )
                )
                .id("live-map-\(card.id)")
                .opacity(liveMapOpacity)
                .animation(.easeInOut(duration: Self.liveCrossFadeDuration), value: liveMapOpacity)
                .allowsHitTesting(isStackCenter || isExpanded)
                .environment(\.geokitMapIsTransitioning, cardIsTransitioning && !isPredictedIncomingCenter)
                .onPreferenceChange(GeoKitMapCameraFrameKey.self) { frame in
                    if let frame { card.lastCameraFrame = frame }
                }
                .onPreferenceChange(GeoKitMapRenderedKey.self) { rendered in
                    if rendered { card.isMapRendered = true }
                }
                .preference(key: AXCardLiveRenderingKey.self, value: card.isMapRendered)
            }

            if card.frozenSnapshot == nil, !shouldShowLoading {
                mediaPlaceholderColor
            }

            if shouldShowLoading {
                AX.CardMediaLoadingOverlay()
            }
        }
        .geokitSelfManagedMapMedia(
            card: card,
            isCentered: isStackCenter,
            provider: mapProviderId,
            mapSize: mapContentSize,
            generation: mediaStore.mapMediaGeneration,
            loadAllowed: !isExpanded
                && !mediaStore.isFanBootstrapping
                && ((mediaLoadAllowed && !isStackCenter) || (isStackCenter && card.frozenSnapshot == nil)),
            controller: mediaStore.mapMediaController,
            onLoadingChanged: { mediaStore.setMapLoading($0, cardID: card.id) }
        )
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                if !mediaStore.isLivePreloaded(cardID: card.id) {
                    card.isMapRendered = false
                }
            }
        }
        .onChange(of: isStackCenter) { wasCenter, isCenter in
            if isCenter, !wasCenter {
                if !card.isMapRendered {
                    card.lastCameraFrame = nil
                }
            }
            mediaStore.syncStackLivePreloadFromDeck()
        }
        .onChange(of: card.frozenSnapshot) { _, _ in
            mediaStore.syncStackLivePreloadFromDeck()
        }
        .onChange(of: mapProviderId) { _, _ in
            card.isMapRendered = false
            card.lastCameraFrame = nil
        }
        .accessibilityIdentifier("geokit-test-app.card")
    }

}
