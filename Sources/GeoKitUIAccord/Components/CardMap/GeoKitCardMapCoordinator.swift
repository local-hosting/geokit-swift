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
        syncCenterMedia(session: session, skipSnapshotCapture: skipSnapshotCapture)
    }

    func handleCollectionIdentityChange(session: AXCardMediaLoadSession) {
        commitDragWarmHandoffIfNeeded(session: session)
        syncCenterMedia(session: session)
    }

    func handleCenterIndexChange(session: AXCardMediaLoadSession) {
        commitDragWarmHandoffIfNeeded(session: session)
        syncCenterLive(session: session)
        if !session.isExpanded {
            syncCenterMedia(session: session)
        }
    }

    func handleExpandedChange(expanded: Bool, session: AXCardMediaLoadSession) {
        syncCenterLive(session: session)
        if expanded {
            refreshVisibleFanPeeks(session: session)
        } else {
            syncCenterMedia(session: session)
        }
    }

    func handleContainerWidthChange(session: AXCardMediaLoadSession) {
        syncCenterMedia(session: session)
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
        syncCenterMedia(session: session)
    }

    func handleCollapsedFrameChange(session: AXCardMediaLoadSession) {
        guard !session.isExpanded, !session.isCollapsing else { return }
        syncCenterMedia(session: session)
    }

    func handleCollapseFinished(wasCollapsing: Bool, session: AXCardMediaLoadSession) {
        guard wasCollapsing, !session.isCollapsing, !session.isExpanded else { return }
        syncCenterLive(session: session)
        syncCenterMedia(session: session)
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

    public func isCenterPeekReady(centerCard: Card?) -> Bool {
        guard let centerCard else { return false }
        let camera = cameraStore.frame(for: centerCard.id)
        return centerCard.hasUsableSnapshot(for: provider, cameraFrame: camera)
    }

    // MARK: - Internal media sync

    private func syncCenterLive(session: AXCardMediaLoadSession) {
        guard let collection = boundCollection else { return }
        let cards = collection.cards
        mediaStore.syncCenterLive(cards: cards, centerIndex: session.centerIndex)
    }

    private func syncCenterMedia(session: AXCardMediaLoadSession, skipSnapshotCapture: Bool = false) {
        guard let collection = boundCollection else { return }
        guard !mediaStore.isSnapshotBootstrapping else { return }
        let size = collapsedMapContentSize
        guard AX.Layout.isValidCardMediaLayoutSize(size) else { return }
        mediaStore.updateMapContentSize(size)
        let cards = collection.cards
        seedCamerasFromPins(in: cards)
        mediaStore.refreshCenter(
            cards: cards,
            centerIndex: session.centerIndex,
            provider: provider,
            skipSnapshotCapture: skipSnapshotCapture,
            onMediaReady: { [weak collection] index in
                collection?.handleMediaEvent(.mediaReady(kind: .map), at: index)
            }
        )
    }

    private func refreshVisibleFanPeeks(session: AXCardMediaLoadSession) {
        guard let collection = boundCollection else { return }
        let size = collapsedMapContentSize
        guard AX.Layout.isValidCardMediaLayoutSize(size) else { return }
        mediaStore.updateMapContentSize(size)
        let cards = collection.cards
        seedCamerasFromPins(in: cards)
        mediaStore.refreshFanPeeks(
            cards: cards,
            centerIndex: session.centerIndex,
            provider: provider,
            onMediaReady: { [weak collection] index in
                collection?.handleMediaEvent(.mediaReady(kind: .map), at: index)
            }
        )
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
        mediaStore.commitDragWarmHandoff(
            cards: collection.cards,
            centerIndex: session.centerIndex
        )
    }
}
#endif
