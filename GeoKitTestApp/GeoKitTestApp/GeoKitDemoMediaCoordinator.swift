#if os(iOS)
import AccordDesignSystem
import GeoKitUI
import GeoKitContract
import SwiftUI
import UIKit

@MainActor
final class GeoKitDemoMediaStore: ObservableObject {
    let mapMediaController = GeoKitCardMapMediaController.shared

    @Published private(set) var mapMediaGeneration: UInt = 0
    @Published private(set) var liveCardIDs: Set<String> = []
    @Published private(set) var mapContentSize: CGSize = .zero
    @Published private(set) var loadingCardIDs: Set<String> = []
    @Published private(set) var stackLiveDragOffset: CGFloat = 0

    private var fanBootstrapTask: Task<Void, Never>?
    private var fanBootstrapScheduledTask: Task<Void, Never>?
    private var fanBootstrapCenterCardID: String?

    @Published private(set) var isFanBootstrapping = false
    private var pendingStackLivePreload = false
    private weak var deckRef: GeoKitDemoDeck?
    private var stackContainerWidth: CGFloat = 0

    init() {
        isFanBootstrapping = true
    }

    func bindDeck(_ deck: GeoKitDemoDeck) {
        deckRef = deck
    }

    /// 0…1 reveal of the incoming center card while the front card is dragged off.
    var incomingCenterDragRevealProgress: CGFloat {
        guard stackContainerWidth > 0, stackLiveDragOffset < 0 else { return 0 }
        return min(1, abs(stackLiveDragOffset) / stackContainerWidth)
    }

    var isDraggingToNextCard: Bool {
        stackLiveDragOffset < -AX.StackConstants.dragMinimumDistance
    }

    func isLivePreloaded(cardID: String) -> Bool {
        liveCardIDs.contains(cardID)
    }

    func syncStackLivePreload(cards: [GeoKitDemoCard], centerIndex: Int) {
        if isFanBootstrapping {
            pendingStackLivePreload = true
            return
        }
        promoteStackLiveAfterStaticBootstrap(cards: cards, centerIndex: centerIndex)
    }

    func syncStackLivePreloadFromDeck() {
        guard let deck = deckRef else { return }
        syncStackLivePreload(cards: deck.cards, centerIndex: 0)
    }

    /// Front card drag left — the card behind center is about to become live; mount it now.
    func handleIncomingCenterDrag(
        liveDragOffset: CGFloat,
        containerWidth: CGFloat,
        cards: [GeoKitDemoCard],
        centerIndex: Int
    ) {
        stackLiveDragOffset = liveDragOffset
        stackContainerWidth = containerWidth

        guard liveDragOffset < -AX.StackConstants.dragMinimumDistance else { return }
        let incomingIndex = centerIndex + 1
        guard cards.indices.contains(incomingIndex) else { return }

        var ids = liveCardIDs
        if cards.indices.contains(centerIndex) {
            ids.insert(cards[centerIndex].id)
        }
        ids.insert(cards[incomingIndex].id)
        guard ids != liveCardIDs else { return }
        liveCardIDs = ids
    }

    private func applyCenterLivePreload(cards: [GeoKitDemoCard], centerIndex: Int) {
        guard cards.indices.contains(centerIndex) else { return }
        liveCardIDs.insert(cards[centerIndex].id)
    }

    private func applyBehindLivePreload(cards: [GeoKitDemoCard], centerIndex: Int) {
        let behindIndex = centerIndex + 1
        guard cards.indices.contains(behindIndex) else { return }
        liveCardIDs.insert(cards[behindIndex].id)
    }

    func isMapLoading(cardID: String) -> Bool {
        loadingCardIDs.contains(cardID)
    }

    func setMapLoading(_ isLoading: Bool, cardID: String) {
        if isLoading {
            loadingCardIDs.insert(cardID)
        } else {
            loadingCardIDs.remove(cardID)
        }
    }

    func updateMapContentSize(_ size: CGSize) {
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: size) else { return }
        mapContentSize = size
    }

    func invalidateAllSnapshots(in cards: [GeoKitDemoCard]) {
        fanBootstrapTask?.cancel()
        fanBootstrapScheduledTask?.cancel()
        fanBootstrapCenterCardID = nil
        isFanBootstrapping = false
        pendingStackLivePreload = false
        stackLiveDragOffset = 0
        mapMediaGeneration &+= 1
        liveCardIDs = []
        loadingCardIDs.removeAll()
        for card in cards {
            card.frozenSnapshot = nil
            card.snapshotPrefetchScheduled = false
            card.isMapRendered = false
            card.lastCameraFrame = nil
        }
    }

    func scheduleBootstrapFanSnapshots(
        cards: [GeoKitDemoCard],
        centerIndex: Int,
        provider: MapProviderId,
        debounceMs: Int = 120,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard cards.indices.contains(centerIndex) else { return }
        let centerID = cards[centerIndex].id
        if fanBootstrapCenterCardID == centerID,
           let task = fanBootstrapTask,
           !task.isCancelled {
            return
        }

        fanBootstrapScheduledTask?.cancel()
        let run = { [weak self] in
            guard let self else { return }
            self.runBootstrapFanSnapshots(
                cards: cards,
                centerIndex: centerIndex,
                provider: provider,
                onMediaReady: onMediaReady
            )
        }

        if debounceMs <= 0 {
            run()
            return
        }

        reserveFanBootstrapWindow()
        fanBootstrapScheduledTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(debounceMs))
            guard !Task.isCancelled else { return }
            run()
        }
    }

    private func reserveFanBootstrapWindow() {
        isFanBootstrapping = true
        pendingStackLivePreload = false
        liveCardIDs = []
    }

    private func runBootstrapFanSnapshots(
        cards: [GeoKitDemoCard],
        centerIndex: Int,
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard cards.indices.contains(centerIndex) else {
            isFanBootstrapping = false
            return
        }

        let center = cards[centerIndex]

        if center.frozenSnapshot != nil {
            promoteStackLiveAfterStaticBootstrap(cards: cards, centerIndex: centerIndex)
            fanBootstrapCenterCardID = center.id
            fanBootstrapTask?.cancel()
            fanBootstrapTask = Task { [weak self] in
                guard let self else { return }
                await self.captureImmediateBehindSnapshotIfNeeded(
                    cards: cards,
                    centerIndex: centerIndex,
                    provider: provider,
                    onMediaReady: onMediaReady
                )
            }
            return
        }

        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: mapContentSize) else {
            isFanBootstrapping = false
            return
        }

        if fanBootstrapCenterCardID == center.id,
           let existing = fanBootstrapTask,
           !existing.isCancelled {
            return
        }

        fanBootstrapTask?.cancel()
        fanBootstrapCenterCardID = center.id
        reserveFanBootstrapWindow()

        fanBootstrapTask = Task { [weak self] in
            guard let self else { return }
            defer { self.endFanBootstrapWindow() }

            await self.mapMediaController.ensureStaticSnapshot(
                for: center,
                size: self.mapContentSize,
                provider: provider,
                priority: .top,
                onLoadingChanged: { self.setMapLoading($0, cardID: center.id) }
            )
            guard !Task.isCancelled else { return }
            if center.frozenSnapshot != nil {
                onMediaReady(centerIndex)
            }

            await self.captureImmediateBehindSnapshotIfNeeded(
                cards: cards,
                centerIndex: centerIndex,
                provider: provider,
                onMediaReady: onMediaReady
            )
            guard !Task.isCancelled else { return }
            self.promoteStackLiveAfterStaticBootstrap(cards: cards, centerIndex: centerIndex)
        }
    }

    private func endFanBootstrapWindow() {
        isFanBootstrapping = false
        if pendingStackLivePreload {
            pendingStackLivePreload = false
            syncStackLivePreloadFromDeck()
        } else {
            pendingStackLivePreload = false
        }
    }

    private func promoteStackLiveAfterStaticBootstrap(cards: [GeoKitDemoCard], centerIndex: Int) {
        applyCenterLivePreload(cards: cards, centerIndex: centerIndex)
        applyBehindLivePreload(cards: cards, centerIndex: centerIndex)
    }

    private func captureImmediateBehindSnapshotIfNeeded(
        cards: [GeoKitDemoCard],
        centerIndex: Int,
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) async {
        let behindIndex = centerIndex + 1
        guard cards.indices.contains(behindIndex) else { return }
        let card = cards[behindIndex]
        guard card.frozenSnapshot == nil else {
            onMediaReady(behindIndex)
            return
        }
        await mapMediaController.ensureStaticSnapshot(
            for: card,
            size: mapContentSize,
            provider: provider,
            priority: .background,
            onLoadingChanged: { self.setMapLoading($0, cardID: card.id) }
        )
        if card.frozenSnapshot != nil {
            onMediaReady(behindIndex)
            applyBehindLivePreload(cards: cards, centerIndex: centerIndex)
        }
    }
}
#endif
