#if os(iOS)
import AccordDesignSystem
import GeoKitUI
import GeoKitContract
import SwiftUI
import UIKit

@MainActor
final class GeoKitDemoMediaStore: ObservableObject {
    let mapMediaController = GeoKitCardMapMediaController.shared
    let cameraStore: MapCameraStore

    init(cameraStore: MapCameraStore) {
        self.cameraStore = cameraStore
    }

    @Published private(set) var mapMediaGeneration: UInt = 0
    @Published private(set) var mapContentSize: CGSize = .zero
    @Published private(set) var loadingCardIDs: Set<String> = []
    @Published private(set) var isSnapshotBootstrapping = false

    /// Single persistent live map owner — same Mapbox surface from collapsed through expand/collapse.
    @Published private(set) var liveCardID: String?

    private var fanBootstrapTask: Task<Void, Never>?
    private var fanBootstrapScheduledTask: Task<Void, Never>?
    private var fanBootstrapCenterCardID: String?

    func isLiveEnabled(cardID: String) -> Bool {
        liveCardID == cardID
    }

    func syncCenterLive(cards: [GeoKitDemoCard], centerIndex: Int, provider: MapProviderId) {
        guard !isSnapshotBootstrapping else { return }
        guard cards.indices.contains(centerIndex) else {
            liveCardID = nil
            return
        }
        let center = cards[centerIndex]
        let centerCamera = cameraStore.frame(for: center.id)
        liveCardID = MapLiveCardSelectionPolicy.liveCardID(
            centerCardID: center.id,
            centerHasUsableSnapshot: center.hasUsableSnapshot(for: provider, cameraFrame: centerCamera),
            centerMapRendered: center.isMapRendered(for: provider)
        )
    }

    func syncCenterLiveFromDeck(_ deck: GeoKitDemoDeck, provider: MapProviderId) {
        syncCenterLive(cards: deck.cards, centerIndex: deck.currentIndex, provider: provider)
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
        isSnapshotBootstrapping = false
        mapMediaGeneration &+= 1
        liveCardID = nil
        loadingCardIDs.removeAll()
        for card in cards {
            card.mapProviderSnapshotCache.removeAll()
            card.clearMapRendered()
        }
    }

    /// Tear down live map state when switching providers — cached per-provider snapshots are preserved.
    func prepareForProviderSwitch(in cards: [GeoKitDemoCard]) {
        fanBootstrapTask?.cancel()
        fanBootstrapScheduledTask?.cancel()
        fanBootstrapCenterCardID = nil
        isSnapshotBootstrapping = false
        mapMediaGeneration &+= 1
        liveCardID = nil
        loadingCardIDs.removeAll()
    }

    func scheduleBootstrapFanSnapshots(
        cards: [GeoKitDemoCard],
        centerIndex: Int,
        provider: MapProviderId,
        debounceMs: Int = 120,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard cards.indices.contains(centerIndex) else { return }
        #if DEBUG
        if GeoKitDemoLaunchArguments.isUITestMode {
            isSnapshotBootstrapping = false
                liveCardID = cards[centerIndex].id
            onMediaReady(centerIndex)
            return
        }
        #endif
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

        fanBootstrapScheduledTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(debounceMs))
            guard !Task.isCancelled else { return }
            run()
        }
    }

    private func runBootstrapFanSnapshots(
        cards: [GeoKitDemoCard],
        centerIndex: Int,
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard cards.indices.contains(centerIndex) else {
            finishSnapshotBootstrap(cards: cards, centerIndex: centerIndex, provider: provider)
            return
        }

        let center = cards[centerIndex]
        let centerCamera = cameraStore.frame(for: center.id)

        if center.hasUsableSnapshot(for: provider, cameraFrame: centerCamera) {
            fanBootstrapCenterCardID = center.id
            fanBootstrapTask?.cancel()
            fanBootstrapTask = Task { [weak self] in
                guard let self else { return }
                defer { self.finishSnapshotBootstrap(cards: cards, centerIndex: centerIndex, provider: provider) }
                onMediaReady(centerIndex)
                await self.captureFanSnapshotsIfNeeded(
                    cards: cards,
                    centerIndex: centerIndex,
                    provider: provider,
                        onMediaReady: onMediaReady
                )
            }
            return
        }

        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: mapContentSize) else {
            finishSnapshotBootstrap(cards: cards, centerIndex: centerIndex, provider: provider)
            return
        }

        if fanBootstrapCenterCardID == center.id,
           let existing = fanBootstrapTask,
           !existing.isCancelled {
            return
        }

        fanBootstrapTask?.cancel()
        fanBootstrapCenterCardID = center.id
        beginSnapshotBootstrap()

        fanBootstrapTask = Task { [weak self] in
            guard let self else { return }
            defer { self.finishSnapshotBootstrap(cards: cards, centerIndex: centerIndex, provider: provider) }

            await self.mapMediaController.ensureStaticSnapshot(
                for: center,
                size: self.mapContentSize,
                provider: provider,
                priority: .top,
                cameraFrame: self.cameraStore.frame(for: center.id),
                onLoadingChanged: { self.setMapLoading($0, cardID: center.id) }
            )
            guard !Task.isCancelled else { return }
            if center.hasUsableSnapshot(
                for: provider,
                cameraFrame: self.cameraStore.frame(for: center.id)
            ) {
                onMediaReady(centerIndex)
            }

            await self.captureFanSnapshotsIfNeeded(
                cards: cards,
                centerIndex: centerIndex,
                provider: provider,
                onMediaReady: onMediaReady
            )
        }
    }

    private func beginSnapshotBootstrap() {
        isSnapshotBootstrapping = true
        liveCardID = nil
    }

    private func finishSnapshotBootstrap(
        cards: [GeoKitDemoCard],
        centerIndex: Int,
        provider: MapProviderId
    ) {
        isSnapshotBootstrapping = false
        syncCenterLive(cards: cards, centerIndex: centerIndex, provider: provider)
    }

    private func captureFanSnapshotsIfNeeded(
        cards: [GeoKitDemoCard],
        centerIndex: Int,
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) async {
        #if DEBUG
        if GeoKitDemoLaunchArguments.isUITestMode { return }
        #endif
        guard centerIndex + 1 < cards.count else { return }
        for index in (centerIndex + 1)..<cards.count {
            let card = cards[index]
            let cardCamera = cameraStore.frame(for: card.id)
            guard !card.hasUsableSnapshot(for: provider, cameraFrame: cardCamera) else {
                onMediaReady(index)
                continue
            }
            await mapMediaController.ensureStaticSnapshot(
                for: card,
                size: mapContentSize,
                provider: provider,
                priority: .background,
                cameraFrame: cameraStore.frame(for: card.id),
                onLoadingChanged: { self.setMapLoading($0, cardID: card.id) }
            )
            if card.hasUsableSnapshot(for: provider, cameraFrame: cardCamera) {
                onMediaReady(index)
            }
        }
    }
}
#endif
