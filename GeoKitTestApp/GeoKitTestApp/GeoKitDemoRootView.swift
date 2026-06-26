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
    @State private var liveMapSurfaceFrame: CGRect = .zero
    @State private var liveMapSurfaceCornerRadius: CGFloat = AX.Radius.card

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

                persistentMapOverlay
                    .zIndex(1)

                cardStackRegion
                    .zIndex(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onPreferenceChange(AXCardMediaSurfaceFramePreferenceKey.self) { entries in
                guard let liveID = mediaStore.liveCardID,
                      let entry = entries.first(where: { $0.cardID == liveID }),
                      MapLiveSurfaceFrameResolver.isValidHostFrame(entry.frame) else { return }
                var transaction = Transaction()
                if deck.isExpanded || deck.isCollapsing {
                    transaction.animation = AX.Animation.expansionSpring
                } else if deck.isTransitioning {
                    transaction.animation = AX.Animation.deckSpring
                }
                withTransaction(transaction) {
                    liveMapSurfaceFrame = entry.frame
                    if let radius = entry.cornerRadius {
                        liveMapSurfaceCornerRadius = radius
                    }
                }
            }
            .axGlassPlacement(.overScene)
        }
        .accessibilityIdentifier("geokit-test-app.root")
    }

    private var resolvedLiveMapFrame: CGRect {
        MapLiveSurfaceFrameResolver.resolve(
            reportedFrame: liveMapSurfaceFrame,
            collapsedCardFrame: deck.collapsedCardFrame
        )
    }

    @ViewBuilder
    private var persistentMapOverlay: some View {
        let mapFrame = resolvedLiveMapFrame
        if let liveID = mediaStore.liveCardID,
           let card = deck.cards.first(where: { $0.id == liveID }),
           MapLiveSurfaceFrameResolver.isValidHostFrame(mapFrame) {
            GeoKitDemoPersistentMapHost(
                cameraStore: cameraStore,
                card: card,
                frame: mapFrame,
                cornerRadius: liveMapSurfaceCornerRadius,
                collapsedReferenceFrame: deck.collapsedCardFrame,
                isExpanded: deck.isExpanded,
                mapProviderId: mapProviderStore.provider,
                mapIsTransitioning: deck.isCollapsing || deck.isTransitioning
            )
        }
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
        .environment(\.axCardExternalLiveMapHost, true)
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
                if index == deck.currentIndex {
                    mediaStore.syncCenterLiveFromDeck(deck, provider: mapProviderStore.provider)
                }
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

    /// One live map: expanded overlay, or front collapsed card — never cards behind.
    private var activeSnapshot: UIImage? {
        guard card.hasUsableSnapshot(
            for: mapProviderId,
            cameraFrame: cameraStore.frame(for: card.id)
        ) else {
            return nil
        }
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
            hasActiveSnapshot: activeSnapshot != nil,
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
        return !shouldShowLoading && activeSnapshot == nil && !liveMapVisible
    }

    private var reportsLiveRenderingToCard: Bool {
        liveMapVisible || activeSnapshot != nil
    }

    private var reportsMediaSurfaceFrame: Bool {
        guard MapCardMediaPresentationPolicy.reportsMediaSurfaceFrame(presentationContext) else {
            return false
        }
        // Expanded overlay frame comes from ``CardExpanded`` layout metrics, not content geometry.
        if isExpanded { return false }
        // Hidden stack slots share the same cardID and must not compete with the overlay.
        if deckExpanded && !isExpanded { return false }
        return true
    }

    private var mediaPlaceholderColor: Color {
        if isExpanded || cardIsCollapsing || showsPaintedLiveMap {
            return AX.Colors.blackRussian
        }
        return Color(white: 0.94)
    }

    var body: some View {
        ZStack {
            if let image = activeSnapshot, !isExpanded {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(showsPaintedLiveMap ? 0 : 1)
                    .animation(.easeInOut(duration: Self.liveCrossFadeDuration), value: showsPaintedLiveMap)
                    .allowsHitTesting(false)
            }

            Color.clear
                .preference(key: AXCardLiveRenderingKey.self, value: reportsLiveRenderingToCard)

            if showsBlankPlaceholder {
                mediaPlaceholderColor
            }

            if shouldShowLoading {
                AX.CardMediaLoadingOverlay()
                    .accessibilityIdentifier(
                        isStackCenter ? "geokit-test-app.card-loading" : "geokit-test-app.card-loading-fan"
                    )
            }
        }
        .geokitSelfManagedMapMedia(
            card: card,
            isCentered: isStackCenter,
            provider: mapProviderId,
            mapSize: mapContentSize,
            generation: mediaStore.mapMediaGeneration,
            loadAllowed: MapCardMediaPresentationPolicy.snapshotLoadAllowed(
                isExpandedOverlaySlot: isExpanded,
                isSnapshotBootstrapping: mediaStore.isSnapshotBootstrapping,
                mediaLoadAllowed: mediaLoadAllowed,
                isStackCenter: isStackCenter,
                isStackOneBehind: isStackOneBehind,
                hasActiveSnapshot: activeSnapshot != nil
            ),
            cameraFrame: cameraStore.frame(for: card.id),
            controller: mediaStore.mapMediaController,
            onLoadingChanged: { mediaStore.setMapLoading($0, cardID: card.id) }
        )
        .axReportsCardMediaSurfaceFrame(cardID: card.id, active: reportsMediaSurfaceFrame)
        .allowsHitTesting(isExpanded)
        .onChange(of: showsLiveMap) { wasLive, isLive in
            if wasLive, !isLive, activeSnapshot == nil {
                card.setMapRendered(false, for: mapProviderId)
            }
        }
        .accessibilityIdentifier("geokit-test-app.card-\(card.id)")
    }
}
