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
    @StateObject private var cameraStore: MapCameraStore
    @StateObject private var mediaStore: GeoKitDemoMediaStore

    init() {
        let cameraStore = MapCameraStore()
        _cameraStore = StateObject(wrappedValue: cameraStore)
        _mediaStore = StateObject(wrappedValue: GeoKitDemoMediaStore(cameraStore: cameraStore))
    }
    @Namespace private var cardNamespace

    /// Keep main-screen chrome visible while the front card expands on top of the stack.
    private var showsMapProviderPicker: Bool {
        !deck.isCollapsing
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
            cardStackRegion
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
                let count = deck.cards.count
                guard !deck.isExpanded, count > 0 else { return }
                deck.rotateStackToPage((deck.stackPageIndex + index) % count)
            },
            isInteractionBlocked: { _ in deck.isExpanded },
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
                .accessibilityIdentifier("geokit-test-app.card-badge-\(card.id)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("geokit-test-app.stack")
        .overlay(alignment: .bottom) {
            if deck.cards.count > 1 {
                Color.clear
                    .frame(height: 28)
                    .accessibilityIdentifier("geokit-test-app.stack-paging")
                    .allowsHitTesting(false)
            }
        }
        .background {
            GeoKitDemoBackdropActivationView()
        }
        .onAppear {
            syncFanSnapshots(force: true)
            #if DEBUG
            if !GeoKitDemoLaunchArguments.isUITestMode {
                GeoKitDemoCaptureHarness.scheduleExpandCapture(deck: deck)
            }
            #endif
        }
        .onChange(of: deck.stackPageIndex) { _, _ in
            syncFanSnapshots(debounceMs: 0)
        }
        .onChange(of: deck.containerWidth) { _, _ in
            syncFanSnapshots()
        }
        .onChange(of: mapProviderStore.provider) { _, _ in
            mediaStore.prepareForProviderSwitch(in: deck.cards)
            syncFanSnapshots(force: true)
        }
        .onChange(of: deck.collapsedCardFrame.size) { _, size in
            guard AX.Layout.isValidCardMediaLayoutSize(size) else { return }
            guard !deck.isExpanded, !deck.isCollapsing else { return }
            syncFanSnapshots()
        }
        .onChange(of: deck.isCollapsing) { wasCollapsing, collapsing in
            guard wasCollapsing, !collapsing, !deck.isExpanded else { return }
            finishCollapseMediaHandoff()
        }
        .environmentObject(mediaStore)
        .environmentObject(cameraStore)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top, spacing: 0) {
            if showsMapProviderPicker {
                mapProviderHeader
            }
        }
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

    /// Hand stack live back to the front card after the collapse animation finishes.
    private func finishCollapseMediaHandoff() {
        mediaStore.syncCenterLiveFromDeck(deck, provider: mapProviderStore.provider)
    }

    private func syncFanSnapshots(force: Bool = false, debounceMs: Int = 120) {
        guard AX.Layout.isValidCardMediaLayoutSize(collapsedMapContentSize) else { return }
        mediaStore.updateMapContentSize(collapsedMapContentSize)
        mediaStore.scheduleBootstrapFanSnapshots(
            cards: deck.cards,
            centerIndex: deck.currentIndex,
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
    @EnvironmentObject private var cameraStore: MapCameraStore
    let isExpanded: Bool
    let mapProviderId: MapProviderId
    let mapContentSize: CGSize

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

    private var activeSnapshot: UIImage? {
        guard card.hasUsableSnapshot(
            for: mapProviderId,
            cameraFrame: cameraStore.frame(for: card.id)
        ) else {
            return nil
        }
        return card.frozenSnapshot(for: mapProviderId)
    }

    /// Any cached peek image — show while a fresh snapshot is captured or live tiles warm up.
    private var displaySnapshot: UIImage? {
        if let activeSnapshot { return activeSnapshot }
        return card.frozenSnapshot(for: mapProviderId)
    }

    private var presentationContext: MapCardMediaPresentationContext {
        MapCardMediaPresentationContext(
            isStackCenter: isStackCenter,
            isStackOneBehind: isStackOneBehind,
            deckExpanded: deckExpanded,
            isExpandedOverlaySlot: isExpanded,
            cardIsTransitioning: cardIsTransitioning,
            cardIsCollapsing: cardIsCollapsing,
            isLiveEnabled: mediaStore.isLiveEnabled(cardID: card.id),
            isMapRendered: card.isMapRendered(for: mapProviderId),
            hasActiveSnapshot: displaySnapshot != nil,
            isCenteredInStack: isCentered
        )
    }

    private var showsLiveMap: Bool {
        MapCardMediaPresentationPolicy.showsLiveMap(presentationContext)
    }

    private var showsPaintedLiveMap: Bool {
        showsLiveMap && card.isMapRendered(for: mapProviderId)
    }

    private var liveMapVisible: Bool {
        MapCardMediaPresentationPolicy.liveMapVisible(presentationContext)
    }

    private var shouldShowLoading: Bool {
        MapCardMediaPresentationPolicy.shouldShowLoadingOverlay(presentationContext)
    }

    private var showsBlankPlaceholder: Bool {
        if isExpanded { return false }
        return !shouldShowLoading && displaySnapshot == nil && !liveMapVisible && !showsLiveMap
    }

    private var reportsLiveRenderingToCard: Bool {
        liveMapVisible || displaySnapshot != nil
    }

    private var peekSnapshotLoadAllowed: Bool {
        guard !isExpanded, !mediaStore.isSnapshotBootstrapping else { return false }
        if isStackCenter { return activeSnapshot == nil }
        if stackOffset > 0, !deckExpanded { return displaySnapshot == nil }
        return false
    }

    private var mapIsTransitioning: Bool {
        cardIsTransitioning || cardIsCollapsing
    }

    private var cardMediaLoadingChrome: some View {
        ZStack {
            if displaySnapshot == nil {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(GeoKitMapTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Loading")
        .accessibilityIdentifier(
            isStackCenter ? "geokit-test-app.card-loading" : "geokit-test-app.card-loading-fan"
        )
    }

    var body: some View {
        ZStack {
            GeoKitMapTheme.placeholderBackground

            if let image = displaySnapshot, !showsPaintedLiveMap {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .allowsHitTesting(false)
            }

            if showsLiveMap {
                GeoKitDemoInCardLiveMap(
                    cameraStore: cameraStore,
                    card: card,
                    isExpanded: isExpanded,
                    mapProviderId: mapProviderId,
                    mapIsTransitioning: mapIsTransitioning
                )
                .id(card.id)
            }

            Color.clear
                .preference(key: AXCardLiveRenderingKey.self, value: reportsLiveRenderingToCard)

            if shouldShowLoading {
                cardMediaLoadingChrome
            }
        }
        .geokitSelfManagedMapMedia(
            card: card,
            isCentered: isStackCenter,
            provider: mapProviderId,
            mapSize: mapContentSize,
            generation: mediaStore.mapMediaGeneration,
            loadAllowed: peekSnapshotLoadAllowed,
            cameraFrame: cameraStore.frame(for: card.id),
            controller: mediaStore.mapMediaController,
            onLoadingChanged: { mediaStore.setMapLoading($0, cardID: card.id) }
        )
        .allowsHitTesting(isExpanded)
        .onChange(of: showsLiveMap) { wasLive, isLive in
            if wasLive, !isLive, displaySnapshot == nil {
                card.setMapRendered(false, for: mapProviderId)
            }
        }
        .accessibilityIdentifier("geokit-test-app.card-\(card.id)")
    }
}
