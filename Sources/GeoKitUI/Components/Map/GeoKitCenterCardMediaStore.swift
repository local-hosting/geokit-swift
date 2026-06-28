#if canImport(UIKit) || canImport(AppKit)
import Combine
import CoreGraphics
import Foundation
import GeoKitContract

/// Center-card media orchestration: center snapshot → live, then background fan peeks.
@MainActor
public final class GeoKitCenterCardMediaStore<Card: GeoKitMapSnapshotCard>: ObservableObject {
    let snapshotController: GeoKitMapSnapshotControlling
    public let cameraStore: MapCameraStore

    public init(cameraStore: MapCameraStore, snapshotController: GeoKitMapSnapshotControlling) {
        self.cameraStore = cameraStore
        self.snapshotController = snapshotController
    }

    @Published public private(set) var mapMediaGeneration: UInt = 0
    @Published public private(set) var mapContentSize: CGSize = .zero
    @Published public private(set) var loadingCardIDs: Set<String> = []
    @Published public private(set) var liveCardID: String?
    /// Incoming stack card warming live tiles while the user drags the front card.
    @Published public private(set) var warmLiveCardID: String?
    /// True once the center card has a cheap static peek — used to reveal the stack on first load.
    @Published public private(set) var isInitialCenterPeekReady = false
    /// After the stack is revealed once, later center swaps keep the stack visible.
    @Published public private(set) var hasRevealedCardStack = false
    /// When false, ``GeoKitCardMapHostModifier`` keeps the stack hidden until ``isInitialCenterPeekReady``.
    @Published public var hidesStackUntilInitialCenterPeekReady = true
    /// True while ``prepareCardExpansion`` is capturing the center-card peek used for expand animation.
    @Published public private(set) var isSnapshotBootstrapping = false

    private var centerTask: Task<Void, Never>?
    private var fanTask: Task<Void, Never>?
    private var expansionPrepareTask: Task<Void, Never>?
    /// (cardID, provider) of an in-flight center capture — prevents layout churn from cancel/restarting it.
    private var centerCaptureInFlight: (cardID: String, provider: MapProviderId)?

    public func isLiveEnabled(for cardID: String) -> Bool {
        liveCardID == cardID || warmLiveCardID == cardID
    }

    public func beginDragWarmLive(cardID: String) {
        guard warmLiveCardID != cardID else { return }
        warmLiveCardID = cardID
    }

    public func endDragWarmLive() {
        warmLiveCardID = nil
    }

    /// Promotes drag-warmed live tiles to the new center card before clearing warm state.
    public func commitDragWarmHandoff(cards: [Card], centerIndex: Int) {
        guard cards.indices.contains(centerIndex) else {
            endDragWarmLive()
            return
        }
        let centerID = cards[centerIndex].id
        if warmLiveCardID == centerID {
            liveCardID = centerID
            warmLiveCardID = nil
        } else {
            syncCenterLive(cards: cards, centerIndex: centerIndex)
            endDragWarmLive()
        }
    }

    public func syncCenterLive(cards: [Card], centerIndex: Int) {
        guard cards.indices.contains(centerIndex) else {
            liveCardID = nil
            return
        }
        liveCardID = cards[centerIndex].id
    }

    public func isMapLoading(for cardID: String) -> Bool {
        loadingCardIDs.contains(cardID)
    }

    public func setMapLoading(_ isLoading: Bool, cardID: String) {
        if isLoading {
            loadingCardIDs.insert(cardID)
        } else {
            loadingCardIDs.remove(cardID)
        }
    }

    /// Suppresses the center-card spinner while the stack stays hidden for the initial HTTP peek.
    private func setMapLoadingIfVisible(_ isLoading: Bool, cardID: String) {
        guard hasRevealedCardStack || !hidesStackUntilInitialCenterPeekReady else { return }
        setMapLoading(isLoading, cardID: cardID)
    }

    public func updateMapContentSize(_ size: CGSize) {
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: size) else { return }
        mapContentSize = size
    }

    public func invalidateAllSnapshots(in cards: [Card]) {
        resetMediaState(in: cards)
    }

    public func prepareForProviderSwitch(in cards: [Card]) {
        resetMediaState(in: cards)
    }

    private func resetMediaState(in cards: [Card]) {
        centerTask?.cancel()
        fanTask?.cancel()
        expansionPrepareTask?.cancel()
        centerCaptureInFlight = nil
        isSnapshotBootstrapping = false
        mapMediaGeneration &+= 1
        liveCardID = nil
        warmLiveCardID = nil
        loadingCardIDs.removeAll()
        isInitialCenterPeekReady = false
        hasRevealedCardStack = false
        for card in cards {
            card.mapProviderSnapshotCache.removeAll()
            if let liveCard = card as? any GeoKitLiveMapCard {
                liveCard.clearMapRendered()
            }
        }
    }

    private var layoutReady: Bool {
        MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: mapContentSize)
    }

    private func centerIsLiveRendered(_ center: Card, provider: MapProviderId) -> Bool {
        guard let liveCard = center as? any GeoKitLiveMapCard else { return false }
        return liveCard.isMapRendered(for: provider)
    }

    /// Cheap static peek while center live stays mounted — HTTP capture only, no live suspend.
    private func enqueueBackgroundCenterPeek(
        center: Card,
        centerIndex: Int,
        cards: [Card],
        provider: MapProviderId,
        cameraFrame: MapCameraFrame?,
        onMediaReady: @escaping (Int) -> Void
    ) {
        if centerTask != nil,
           let inFlight = centerCaptureInFlight,
           inFlight.cardID == center.id,
           inFlight.provider == provider {
            return
        }

        centerTask?.cancel()
        centerCaptureInFlight = (center.id, provider)
        centerTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if let inFlight = self.centerCaptureInFlight,
                   inFlight.cardID == center.id, inFlight.provider == provider {
                    self.centerCaptureInFlight = nil
                }
            }

            await self.snapshotController.ensureStaticSnapshot(
                for: center,
                size: self.mapContentSize,
                provider: provider,
                priority: MapSnapshotCapturePolicy.bootstrapPeekPriority,
                cameraFrame: cameraFrame,
                onLoadingChanged: { loading in
                    self.setMapLoadingIfVisible(loading, cardID: center.id)
                }
            )

            guard !Task.isCancelled else { return }
            guard !self.isSnapshotBootstrapping else { return }
            guard cards.indices.contains(centerIndex) else { return }
            self.markInitialCenterPeekReady(cards: cards, centerIndex: centerIndex, provider: provider)
            onMediaReady(centerIndex)
        }
    }

    private func makePlan(cards: [Card], centerIndex: Int, provider: MapProviderId) -> MapMediaRefreshPlan {
        MapMediaRefreshPlanner.plan(
            centerIndex: centerIndex,
            cardCount: cards.count,
            peekRadius: GeoKitMapCardStageConstants.peekRadius,
            layoutReady: layoutReady,
            centerHasSnapshot: cards[centerIndex].hasUsableSnapshot(
                for: provider,
                cameraFrame: cameraStore.frame(for: cards[centerIndex].id)
            ),
            fanHasSnapshot: { index in
                guard cards.indices.contains(index) else { return true }
                let card = cards[index]
                return card.hasUsableSnapshot(for: provider, cameraFrame: self.cameraStore.frame(for: card.id))
            }
        )
    }

    /// Capture a fresh center peek at tap time, then call `onReady` so ``AXCardCollectionModel/expandActiveCard()``
    /// can start the overlay spring with snapshot-only media.
    public func prepareCardExpansion(
        card: Card,
        provider: MapProviderId,
        mapSize: CGSize,
        expansionSnapshotSize: CGSize? = nil,
        cameraFrame: MapCameraFrame?,
        onReady: @escaping () -> Void
    ) {
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: mapSize) else {
            onReady()
            return
        }

        let captureSize = expansionSnapshotSize ?? mapSize
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: captureSize) else {
            onReady()
            return
        }

        expansionPrepareTask?.cancel()
        centerTask?.cancel()
        centerCaptureInFlight = nil
        isSnapshotBootstrapping = true

        expansionPrepareTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isSnapshotBootstrapping = false }

            // GPU snapshotter cannot run while center live Metal is mounted — suspend live first.
            let centerID = card.id
            let hadLiveOnCenter = self.liveCardID == centerID
            self.liveCardID = nil
            await Task.yield()

            await self.snapshotController.ensureStaticSnapshot(
                for: card,
                size: captureSize,
                provider: provider,
                // GPU snapshot at full viewport — matches live camera; never upscaled during the spring.
                priority: MapSnapshotCapturePolicy.expansionPeekPriority,
                cameraFrame: cameraFrame,
                onLoadingChanged: { self.setMapLoading($0, cardID: card.id) },
                forceRecapture: true,
                matchesLiveViewport: true
            )

            guard !Task.isCancelled else {
                if hadLiveOnCenter { self.liveCardID = centerID }
                return
            }
            await MainActor.run { onReady() }
        }
    }

    /// Center peek snapshot, hand off to live, then fan peeks in the background.
    public func refreshCenter(
        cards: [Card],
        centerIndex: Int,
        provider: MapProviderId,
        skipSnapshotCapture: Bool = false,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard cards.indices.contains(centerIndex) else { return }
        guard !isSnapshotBootstrapping else { return }

        if skipSnapshotCapture {
            syncCenterLive(cards: cards, centerIndex: centerIndex)
            markInitialCenterPeekReady(
                cards: cards,
                centerIndex: centerIndex,
                provider: provider,
                allowWithoutSnapshot: true
            )
            onMediaReady(centerIndex)
            return
        }

        let plan = makePlan(cards: cards, centerIndex: centerIndex, provider: provider)
        guard !plan.isNoop else { return }

        if !plan.capturesCenterBeforeLive {
            syncCenterLive(cards: cards, centerIndex: centerIndex)
            markInitialCenterPeekReady(cards: cards, centerIndex: centerIndex, provider: provider)
            onMediaReady(centerIndex)
            captureFan(indices: plan.fanCaptureIndices, cards: cards, provider: provider, onMediaReady: onMediaReady)
            return
        }

        let center = cards[centerIndex]
        let centerCamera = cameraStore.frame(for: center.id)

        // Right-drag release: back card was warming live without a static peek — keep live mounted
        // and capture the HTTP peek in the background instead of suspending to a white card plate.
        if centerIsLiveRendered(center, provider: provider) {
            syncCenterLive(cards: cards, centerIndex: centerIndex)
            warmLiveCardID = nil
            markInitialCenterPeekReady(
                cards: cards,
                centerIndex: centerIndex,
                provider: provider,
                allowWithoutSnapshot: true
            )
            onMediaReady(centerIndex)
            captureFan(indices: plan.fanCaptureIndices, cards: cards, provider: provider, onMediaReady: onMediaReady)
            enqueueBackgroundCenterPeek(
                center: center,
                centerIndex: centerIndex,
                cards: cards,
                provider: provider,
                cameraFrame: centerCamera,
                onMediaReady: onMediaReady
            )
            return
        }

        // Layout churn (card frame settling) calls refreshCenter every animation frame. Cancelling and
        // restarting the Mapbox snapshotter each time means it never finishes loading the style — the card
        // stays dark forever. Let an in-flight capture for the same card+provider run to completion instead.
        if centerTask != nil,
           let inFlight = centerCaptureInFlight,
           inFlight.cardID == center.id,
           inFlight.provider == provider {
            return
        }

        centerTask?.cancel()
        liveCardID = nil
        centerCaptureInFlight = (center.id, provider)
        centerTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if let inFlight = self.centerCaptureInFlight,
                   inFlight.cardID == center.id, inFlight.provider == provider {
                    self.centerCaptureInFlight = nil
                }
            }

            await self.snapshotController.ensureStaticSnapshot(
                for: center,
                size: self.mapContentSize,
                provider: provider,
                priority: MapSnapshotCapturePolicy.bootstrapPeekPriority,
                cameraFrame: centerCamera,
                onLoadingChanged: { loading in
                    self.setMapLoadingIfVisible(loading, cardID: center.id)
                }
            )

            guard !Task.isCancelled else { return }
            guard !self.isSnapshotBootstrapping else { return }

            self.finishInitialCenterBootstrap(
                cards: cards,
                centerIndex: centerIndex,
                provider: provider,
                onMediaReady: onMediaReady
            )
        }
    }

    /// Reveal the stack and hand off to live even when the HTTP peek failed — never leave a blank screen.
    private func finishInitialCenterBootstrap(
        cards: [Card],
        centerIndex: Int,
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard cards.indices.contains(centerIndex) else { return }
        let center = cards[centerIndex]
        let centerCamera = cameraStore.frame(for: center.id)
        let hasPeek = center.frozenSnapshot(for: provider) != nil
            || center.hasUsableSnapshot(for: provider, cameraFrame: centerCamera)

        markInitialCenterPeekReady(
            cards: cards,
            centerIndex: centerIndex,
            provider: provider,
            allowWithoutSnapshot: !hasPeek
        )
        syncCenterLive(cards: cards, centerIndex: centerIndex)
        onMediaReady(centerIndex)
        refreshFanPeeks(
            cards: cards,
            centerIndex: centerIndex,
            provider: provider,
            onMediaReady: onMediaReady
        )
    }

    /// Visible fan slots only — runs after center snapshot + live; Mapbox waits for safe snapshot windows.
    public func refreshFanPeeks(
        cards: [Card],
        centerIndex: Int,
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard cards.indices.contains(centerIndex) else { return }
        let plan = makePlan(cards: cards, centerIndex: centerIndex, provider: provider)
        guard !plan.isNoop else { return }
        captureFan(indices: plan.fanCaptureIndices, cards: cards, provider: provider, onMediaReady: onMediaReady)
    }

    private func captureFan(
        indices: [Int],
        cards: [Card],
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard !indices.isEmpty else { return }

        fanTask?.cancel()
        fanTask = Task { [weak self] in
            guard let self else { return }
            for index in indices {
                guard !Task.isCancelled else { return }
                guard cards.indices.contains(index) else { continue }
                let card = cards[index]
                let camera = self.cameraStore.frame(for: card.id)
                await self.snapshotController.ensureStaticSnapshot(
                    for: card,
                    size: self.mapContentSize,
                    provider: provider,
                    priority: MapSnapshotCapturePolicy.bootstrapPeekPriority,
                    cameraFrame: camera,
                    onLoadingChanged: { self.setMapLoading($0, cardID: card.id) }
                )
                if card.hasUsableSnapshot(for: provider, cameraFrame: camera) {
                    onMediaReady(index)
                }
            }
        }
    }

    private func markInitialCenterPeekReady(
        cards: [Card],
        centerIndex: Int,
        provider: MapProviderId,
        allowWithoutSnapshot: Bool = false
    ) {
        guard cards.indices.contains(centerIndex) else {
            isInitialCenterPeekReady = false
            return
        }
        let center = cards[centerIndex]
        let camera = cameraStore.frame(for: center.id)
        let hasPeek = center.frozenSnapshot(for: provider) != nil
            || center.hasUsableSnapshot(for: provider, cameraFrame: camera)
        guard hasPeek || allowWithoutSnapshot else { return }
        isInitialCenterPeekReady = true
        hasRevealedCardStack = true
    }
}

#if os(iOS)
public extension GeoKitCenterCardMediaStore {
    /// iOS host init — defaults to the shared Mapbox/MapKit capture controller.
    convenience init(cameraStore: MapCameraStore) {
        self.init(cameraStore: cameraStore, snapshotController: GeoKitCardMapMediaController.shared)
    }

    /// Concrete capture controller for SwiftUI card slots that drive live/static mounts.
    var mapMediaController: GeoKitCardMapMediaController { GeoKitCardMapMediaController.shared }

    /// Returns a closure for ``AXCardCollectionModel/prepareCardExpansion`` — capture center peek, then expand.
    func makePrepareCardExpansionHandler(
        provider: @escaping () -> MapProviderId,
        mapSize: @escaping () -> CGSize,
        expansionSnapshotSize: @escaping () -> CGSize? = { nil },
        cameraStore: MapCameraStore
    ) -> (Card, CGRect, @escaping () -> Void) -> Void {
        { card, _, onReady in
            self.prepareCardExpansion(
                card: card,
                provider: provider(),
                mapSize: mapSize(),
                expansionSnapshotSize: expansionSnapshotSize(),
                cameraFrame: cameraStore.frame(for: card.id),
                onReady: onReady
            )
        }
    }
}
#endif

public extension GeoKitLiveMapCard {
    func clearMapRendered() {
        setMapRendered(false, for: .mapbox)
        setMapRendered(false, for: .apple)
    }
}
#endif
