#if os(iOS)
import AccordDesignSystem
import CardMediaContract
import Combine
import CoreGraphics
import GeoKitContract
import GeoKitUI
import SwiftUI

/// Map media store surface for ``GeoKitCardMap`` views — orchestration lives in ``GeoKitCardMapMediaPlugin``.
@MainActor
public final class GeoKitCardMapCoordinator<Card: GeoKitLiveMapCard & AXCardItem>: ObservableObject {
    @Published public var provider: MapProviderId = .mapbox {
        didSet {
            guard oldValue != provider else { return }
            onProviderChanged?(provider)
            handleProviderSwitch()
        }
    }

    public let cameraStore: MapCameraStore
    public let mediaStore: GeoKitCenterCardMediaStore<Card>
    public let loadCoordinator: AXCardMediaLoadCoordinator
    public let mapPlugin: GeoKitCardMapMediaPlugin<Card>

    /// Called when ``provider`` changes so hosts can configure Mapbox/MapKit bootstrap.
    public var onProviderChanged: ((MapProviderId) -> Void)?

    private weak var boundCollection: AXCardCollectionModel<Card>?
    private(set) var boundLayout: CardMediaCollectionLayout = .stack
    private var storeSubscriptions = Set<AnyCancellable>()
    private var lastRefreshLayoutSize: CGSize = .zero

    public init() {
        let cameraStore = MapCameraStore()
        self.cameraStore = cameraStore
        self.mediaStore = GeoKitCenterCardMediaStore(cameraStore: cameraStore)
        self.loadCoordinator = AXCardMediaLoadCoordinator()
        self.mapPlugin = GeoKitCardMapMediaPlugin()
        self.loadCoordinator.register(mapPlugin)
        bindStorePublishers()
    }

    public init(cameraStore: MapCameraStore) {
        self.cameraStore = cameraStore
        self.mediaStore = GeoKitCenterCardMediaStore(cameraStore: cameraStore)
        self.loadCoordinator = AXCardMediaLoadCoordinator()
        self.mapPlugin = GeoKitCardMapMediaPlugin()
        self.loadCoordinator.register(mapPlugin)
        bindStorePublishers()
    }

    private func bindStorePublishers() {
        mediaStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &storeSubscriptions)
        cameraStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &storeSubscriptions)
    }

    public func bind<Collection: AXCardCollectionModel<Card>>(
        collection: Collection,
        layout: CardMediaCollectionLayout,
        skipSnapshotCapture: @escaping () -> Bool = { false }
    ) {
        boundCollection = collection
        boundLayout = layout
        mapPlugin.bind(coordinator: self, collection: collection, skipSnapshotCapture: skipSnapshotCapture)
        primeBootstrapLayoutSize()
    }

    public func unbind() {
        mapPlugin.unbind()
        boundCollection = nil
    }

    public var collapsedMapContentSize: CGSize {
        guard let collection = boundCollection else { return .zero }
        return GeoKitCardMapLayout.collapsedMapContentSize(
            collapsedCardFrame: collection.collapsedCardFrame,
            containerWidth: collection.containerWidth
        )
    }

    public func centerCard(in cards: [Card], session: AXCardMediaLoadSession) -> Card? {
        let index = session.centerContext.mediaCenterIndex
        guard cards.indices.contains(index) else { return nil }
        return cards[index]
    }

    public func centerCard(in cards: [Card]) -> Card? {
        guard let collection = boundCollection else { return cards.first }
        let context = collection.mediaCenterContext(layout: boundLayout)
        let index = context.mediaCenterIndex
        guard cards.indices.contains(index) else { return nil }
        return cards[index]
    }

    // MARK: - Plugin callbacks

    func bootstrapCenterMedia(session: AXCardMediaLoadSession, skipSnapshotCapture: Bool = false) {
        syncCollectionMedia(session: session, skipSnapshotCapture: skipSnapshotCapture)
    }

    func handleCollectionIdentityChange(session: AXCardMediaLoadSession) {
        guard !isDemotedChoreographyActive(session: session) else { return }
        commitDragWarmHandoffIfNeeded(session: session)
        syncCollectionMedia(session: session)
    }

    func handleCenterIndexChange(session: AXCardMediaLoadSession) {
        guard !isDemotedChoreographyActive(session: session) else { return }
        commitDragWarmHandoffIfNeeded(session: session)
        syncFocusedLive(session: session)
        if !session.isExpanded {
            syncCollectionMedia(session: session)
        }
    }

    func handleExpandedChange(expanded: Bool, session: AXCardMediaLoadSession) {
        syncFocusedLive(session: session)
        if expanded {
            captureVisibleStaticSnapshots(session: session)
        } else {
            syncCollectionMedia(session: session)
        }
    }

    func handleContainerWidthChange(session: AXCardMediaLoadSession) {
        updateLayoutSize(from: session)
        guard needsStackMediaSync(session: session) else { return }
        syncCollectionMedia(session: session)
    }

    func handleProviderSwitch() {
        guard let collection = boundCollection else { return }
        mediaStore.prepareForProviderSwitch(in: collection.cards)
        let context = collection.mediaCenterContext(layout: boundLayout)
        let session = AXCardMediaLoadSession(
            layout: boundLayout,
            centerContext: context,
            cardCount: collection.cards.count,
            mediaContentSize: collapsedMapContentSize,
            mediaLoadDepth: collection.mediaLoadDepth
        )
        syncCollectionMedia(session: session)
    }

    func handleCollapsedFrameChange(session: AXCardMediaLoadSession) {
        guard !session.isExpanded, !session.isCollapsing, !session.isTransitioning else { return }
        updateLayoutSize(from: session)
        guard needsStackMediaSync(session: session) else { return }
        syncCollectionMedia(session: session)
    }

    func handleCollapseFinished(wasCollapsing: Bool, session: AXCardMediaLoadSession) {
        guard wasCollapsing, !session.isCollapsing, !session.isExpanded else { return }
        syncFocusedLive(session: session)
        syncCollectionMedia(session: session)
    }

    func handleCardDragChanged(
        session: AXCardMediaLoadSession,
        dragOffset: CGFloat,
        collection: AXCardCollectionModel<Card>?
    ) {
        guard !session.isExpanded else { return }
        guard collection?.cards.count ?? 0 > 1 else {
            mediaStore.endDragWarmLive()
            return
        }
        let threshold = MapDragWarmLivePolicy.dragThreshold(
            containerWidth: session.containerWidth > 0 ? session.containerWidth : session.mediaContentSize.width
        )
        guard let cards = collection?.cards else { return }
        guard let targetIndex = MapDragWarmLivePolicy.warmTargetIndex(
            layout: session.layout,
            cardCount: cards.count,
            centerIndex: session.centerIndex,
            dragOffset: dragOffset,
            threshold: threshold
        ) else {
            mediaStore.endDragWarmLive()
            return
        }
        mediaStore.beginDragWarmLive(cardID: cards[targetIndex].id)
    }

    func handleCardDragCancelled(isTransitioning: Bool) {
        guard !isTransitioning else { return }
        mediaStore.endDragWarmLive()
    }

    func prepareCardExpansion(
        card: Card,
        mapSize: CGSize,
        cameraFrame: MapCameraFrame?,
        onReady: @escaping () -> Void
    ) {
        mediaStore.prepareCardExpansion(
            card: card,
            provider: provider,
            mapSize: mapSize,
            cameraFrame: cameraFrame,
            onReady: onReady
        )
    }

    public func isCenterMediaReady(centerCard: Card?) -> Bool {
        guard let centerCard else { return false }
        let camera = cameraStore.frame(for: centerCard.id)
        if centerCard.hasUsableSnapshot(for: provider, cameraFrame: camera) { return true }
        if centerCard.isMapRendered(for: provider) { return true }
        if mediaStore.isLiveEnabled(for: centerCard.id) { return true }
        return false
    }

    public func isFocusedStaticReady(focusedCard: Card?) -> Bool {
        guard let focusedCard else { return false }
        let camera = cameraStore.frame(for: focusedCard.id)
        return focusedCard.hasUsableSnapshot(for: provider, cameraFrame: camera)
    }

    // MARK: - Internal media sync

    func handleDemotedCardChoreographyEnded(session: AXCardMediaLoadSession) {
        commitDragWarmHandoffIfNeeded(session: session)
        syncFocusedLive(session: session)
        if !session.isExpanded {
            syncCollectionMedia(session: session)
        }
    }

    private func isDemotedChoreographyActive(session: AXCardMediaLoadSession) -> Bool {
        session.recentlyDemotedCardIndex != nil
    }

    private func syncFocusedLive(session: AXCardMediaLoadSession) {
        guard let collection = boundCollection else { return }
        let cards = collection.cards
        if let demotedIndex = session.recentlyDemotedCardIndex, cards.indices.contains(demotedIndex) {
            mediaStore.syncFocusedLive(cards: cards, focusedIndex: demotedIndex)
            return
        }
        mediaStore.syncFocusedLive(cards: cards, focusedIndex: session.centerIndex)
    }

    private func syncCollectionMedia(session: AXCardMediaLoadSession, skipSnapshotCapture: Bool = false) {
        guard let collection = boundCollection else { return }
        if isDemotedChoreographyActive(session: session) {
            captureVisibleStaticSnapshots(session: session)
            return
        }
        guard !mediaStore.isSnapshotBootstrapping else { return }
        guard updateLayoutSize(from: session) else { return }
        let cards = collection.cards
        seedCamerasFromPins(in: cards)
        mediaStore.syncCollectionMedia(
            cards: cards,
            focusedIndex: session.centerIndex,
            provider: provider,
            skipSnapshotCapture: skipSnapshotCapture,
            onMediaReady: { [weak collection] index in
                collection?.handleMediaEvent(.mediaReady(kind: .map), at: index)
            }
        )
    }

    private func captureVisibleStaticSnapshots(session: AXCardMediaLoadSession) {
        guard let collection = boundCollection else { return }
        guard updateLayoutSize(from: session) else { return }
        let cards = collection.cards
        seedCamerasFromPins(in: cards)
        mediaStore.captureVisibleStaticSnapshots(
            cards: cards,
            focusedIndex: session.centerIndex,
            provider: provider,
            onMediaReady: { [weak collection] index in
                collection?.handleMediaEvent(.mediaReady(kind: .map), at: index)
            }
        )
    }

    @discardableResult
    private func updateLayoutSize(from session: AXCardMediaLoadSession) -> Bool {
        let size = collapsedMapContentSize
        guard AX.Layout.isValidCardMediaLayoutSize(size) else { return false }
        if lastRefreshLayoutSize == .zero
            || layoutSizeChangeRequiresMediaRefresh(from: lastRefreshLayoutSize, to: size) {
            mediaStore.updateMapContentSize(size)
            lastRefreshLayoutSize = size
        }
        return true
    }

    private func needsStackMediaSync(session: AXCardMediaLoadSession) -> Bool {
        guard let collection = boundCollection else { return false }
        let cards = collection.cards
        guard cards.indices.contains(session.centerIndex) else { return true }
        let focusedID = cards[session.centerIndex].id
        if mediaStore.liveCardID != focusedID { return true }
        if !mediaStore.hasRevealedCardStack { return true }
        let size = collapsedMapContentSize
        return layoutSizeChangeRequiresMediaRefresh(from: lastRefreshLayoutSize, to: size)
    }

    private func seedCamerasFromPins(in cards: [Card]) {
        for card in cards {
            seedCameraFromPins(for: card)
        }
    }

    private func seedCameraFromPins(for card: Card) {
        guard cameraStore.frame(for: card.id) == nil else { return }
        let request = card.mapSnapshotRequest(provider: provider, cameraFrame: nil)
        let frame = MapCameraFrameResolver.resolve(for: request)
        cameraStore.setFrame(frame, for: card.id)
    }

    private func primeBootstrapLayoutSize() {
        let estimated = GeoKitCardMapLayout.collapsedMapContentSize(
            collapsedCardFrame: .zero,
            containerWidth: 0
        )
        guard AX.Layout.isValidCardMediaLayoutSize(estimated) else { return }
        mediaStore.updateMapContentSize(estimated)
    }

    private func commitDragWarmHandoffIfNeeded(session: AXCardMediaLoadSession) {
        guard let collection = boundCollection else { return }
        guard !isDemotedChoreographyActive(session: session) else { return }
        mediaStore.commitDragWarmHandoff(
            cards: collection.cards,
            focusedIndex: session.centerIndex
        )
    }

    /// Ignore sub-point card spring resize churn once center live is mounted.
    private func layoutSizeChangeRequiresMediaRefresh(from previous: CGSize, to next: CGSize) -> Bool {
        guard previous.width > 0, previous.height > 0 else { return true }
        let widthDelta = abs(next.width - previous.width)
        let heightDelta = abs(next.height - previous.height)
        return widthDelta > 2 || heightDelta > 2
    }
}
#endif
