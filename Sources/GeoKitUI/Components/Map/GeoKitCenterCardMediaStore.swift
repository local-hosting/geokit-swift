#if canImport(UIKit) || canImport(AppKit)
import Combine
import CoreGraphics
import Foundation
import GeoKitContract

/// Card-stack map media: static snapshots for visible cards, one live map on the focused (top) card.
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
    /// After the stack is revealed once, later focus swaps keep the stack visible.
    @Published public private(set) var hasRevealedCardStack = false
    /// When false, ``GeoKitMapHostModifier`` keeps the stack hidden until the collection reports focused media ready.
    @Published public var hidesStackUntilInitialFocusedStaticReady = true
    /// True while ``prepareCardExpansion`` captures the focused-card static used for expand animation.
    @Published public private(set) var isSnapshotBootstrapping = false

    private var focusedCaptureTask: Task<Void, Never>?
    private var visibleStaticCaptureTask: Task<Void, Never>?
    private var expansionPrepareTask: Task<Void, Never>?
    /// In-flight focused capture — layout churn must not restart it for the same card+provider.
    private var focusedCaptureInFlight: (cardID: String, provider: MapProviderId)?
    /// Fan indices currently being captured — layout churn must not restart the same pass.
    private var visibleStaticCaptureInFlight: [Int]?

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

    /// Promotes drag-warmed live tiles to the new focused card before clearing warm state.
    public func commitDragWarmHandoff(cards: [Card], focusedIndex: Int) {
        guard cards.indices.contains(focusedIndex) else {
            endDragWarmLive()
            return
        }
        let focusedID = cards[focusedIndex].id
        if warmLiveCardID == focusedID {
            liveCardID = focusedID
            warmLiveCardID = nil
        } else {
            assignLiveToFocused(cards: cards, focusedIndex: focusedIndex)
            endDragWarmLive()
        }
    }

    public func syncFocusedLive(cards: [Card], focusedIndex: Int) {
        assignLiveToFocused(cards: cards, focusedIndex: focusedIndex)
    }

    private func assignLiveToFocused(cards: [Card], focusedIndex: Int) {
        guard cards.indices.contains(focusedIndex) else {
            liveCardID = nil
            return
        }
        liveCardID = cards[focusedIndex].id
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

    private func setMapLoadingIfStackVisible(_ isLoading: Bool, cardID: String) {
        guard hasRevealedCardStack || !hidesStackUntilInitialFocusedStaticReady else { return }
        setMapLoading(isLoading, cardID: cardID)
    }

    public func updateMapContentSize(_ size: CGSize) {
        guard MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: size) else { return }
        mapContentSize = size
    }

    public func invalidateAllSnapshots(in cards: [Card]) {
        resetMediaState(in: cards, preserveStackReveal: false, preserveSnapshotCache: false)
    }

    public func prepareForProviderSwitch(in cards: [Card]) {
        resetMediaState(in: cards, preserveStackReveal: true, preserveSnapshotCache: true)
    }

    private func cancelMediaTasks() {
        focusedCaptureTask?.cancel()
        visibleStaticCaptureTask?.cancel()
        expansionPrepareTask?.cancel()
        focusedCaptureInFlight = nil
        visibleStaticCaptureInFlight = nil
        isSnapshotBootstrapping = false
    }

    private func resetMediaState(
        in cards: [Card],
        preserveStackReveal: Bool,
        preserveSnapshotCache: Bool
    ) {
        cancelMediaTasks()
        mapMediaGeneration &+= 1
        liveCardID = nil
        warmLiveCardID = nil
        loadingCardIDs.removeAll()
        if !preserveStackReveal {
            hasRevealedCardStack = false
        }
        for card in cards {
            if !preserveSnapshotCache {
                card.mapProviderSnapshotCache.removeAll()
            }
            if let liveCard = card as? any GeoKitLiveMapCard {
                liveCard.clearMapRendered()
            }
        }
    }

    private var layoutReady: Bool {
        MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: mapContentSize)
    }

    private func cardHasStaticSnapshot(_ card: Card, provider: MapProviderId) -> Bool {
        card.hasUsableSnapshot(for: provider, cameraFrame: cameraStore.frame(for: card.id))
    }

    /// Steady-state focused slot: live tiles own the viewport — do not re-chase peek capture on camera drift.
    private func focusedPeekIsSatisfied(_ card: Card, provider: MapProviderId) -> Bool {
        if cardHasStaticSnapshot(card, provider: provider) { return true }
        guard liveCardID == card.id else { return false }
        if card.frozenSnapshot(for: provider) != nil { return true }
        if let liveCard = card as? any GeoKitLiveMapCard,
           liveCard.isMapRendered(for: provider) {
            return true
        }
        return false
    }

    private func shouldDeferFocusedBackgroundPeek(for card: Card, provider: MapProviderId) -> Bool {
        guard liveCardID == card.id else { return false }
        guard let liveCard = card as? any GeoKitLiveMapCard else { return false }
        return liveCard.isMapRendered(for: provider)
    }

    private func visibleStaticCaptureIndices(
        cards: [Card],
        focusedIndex: Int,
        provider: MapProviderId
    ) -> [Int] {
        MapMediaRefreshPlanner.plan(
            centerIndex: focusedIndex,
            cardCount: cards.count,
            peekRadius: GeoKitMapCardStageConstants.peekRadius,
            layoutReady: layoutReady,
            centerHasSnapshot: cardHasStaticSnapshot(cards[focusedIndex], provider: provider),
            fanHasSnapshot: { index in
                guard cards.indices.contains(index) else { return true }
                return self.cardHasStaticSnapshot(cards[index], provider: provider)
            }
        ).fanCaptureIndices
    }

    /// Sync static snapshots and live ownership for the focused card in any collection layout.
    public func syncCollectionMedia(
        cards: [Card],
        focusedIndex: Int,
        provider: MapProviderId,
        skipSnapshotCapture: Bool = false,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard cards.indices.contains(focusedIndex) else { return }
        guard !isSnapshotBootstrapping else { return }
        guard layoutReady else { return }

        if skipSnapshotCapture {
            assignLiveToFocused(cards: cards, focusedIndex: focusedIndex)
            markStackRevealed(cards: cards, focusedIndex: focusedIndex, provider: provider, allowWithoutSnapshot: true)
            onMediaReady(focusedIndex)
            return
        }

        let focused = cards[focusedIndex]
        let focusedHasSnapshot = focusedPeekIsSatisfied(focused, provider: provider)

        // Steady state — focused card already owns live; never suspend for layout churn.
        if liveCardID == focused.id {
            captureVisibleStaticSnapshots(
                cards: cards,
                focusedIndex: focusedIndex,
                provider: provider,
                onMediaReady: onMediaReady
            )
            if !focusedHasSnapshot, !shouldDeferFocusedBackgroundPeek(for: focused, provider: provider) {
                captureFocusedStaticInBackground(
                    focused: focused,
                    focusedIndex: focusedIndex,
                    cards: cards,
                    provider: provider,
                    onMediaReady: onMediaReady
                )
            }
            return
        }

        // Focus handoff or first paint — focused already has a static image.
        if focusedHasSnapshot {
            revealFocusedAndGoLive(
                cards: cards,
                focusedIndex: focusedIndex,
                provider: provider,
                onMediaReady: onMediaReady
            )
            return
        }

        // Bootstrap focused card: static first, then live (focus change or cold start only).
        bootstrapFocusedStaticThenLive(
            focused: focused,
            focusedIndex: focusedIndex,
            cards: cards,
            provider: provider,
            onMediaReady: onMediaReady
        )
    }

    /// Visible fan slots only — static snapshots; never touches live ownership.
    public func captureVisibleStaticSnapshots(
        cards: [Card],
        focusedIndex: Int,
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard cards.indices.contains(focusedIndex) else { return }
        guard layoutReady else { return }
        let indices = visibleStaticCaptureIndices(cards: cards, focusedIndex: focusedIndex, provider: provider)
        captureStaticSnapshots(at: indices, cards: cards, provider: provider, onMediaReady: onMediaReady)
    }

    /// Capture a fresh focused static at tap time, then call `onReady` so expand can start snapshot-only.
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
        focusedCaptureTask?.cancel()
        focusedCaptureInFlight = nil
        isSnapshotBootstrapping = true

        expansionPrepareTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isSnapshotBootstrapping = false }

            let focusedID = card.id
            let hadLiveOnFocused = self.liveCardID == focusedID
            self.liveCardID = nil
            await Task.yield()

            await self.snapshotController.ensureStaticSnapshot(
                for: card,
                size: captureSize,
                provider: provider,
                priority: MapSnapshotCapturePolicy.expansionPeekPriority,
                cameraFrame: cameraFrame,
                onLoadingChanged: { self.setMapLoading($0, cardID: card.id) },
                forceRecapture: true,
                matchesLiveViewport: true
            )

            guard !Task.isCancelled else {
                if hadLiveOnFocused { self.liveCardID = focusedID }
                return
            }
            await MainActor.run {
                if hadLiveOnFocused { self.liveCardID = focusedID }
                onReady()
            }
        }
    }

    // MARK: - Private orchestration

    private func revealFocusedAndGoLive(
        cards: [Card],
        focusedIndex: Int,
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        markStackRevealed(cards: cards, focusedIndex: focusedIndex, provider: provider)
        assignLiveToFocused(cards: cards, focusedIndex: focusedIndex)
        warmLiveCardID = nil
        onMediaReady(focusedIndex)
        captureVisibleStaticSnapshots(
            cards: cards,
            focusedIndex: focusedIndex,
            provider: provider,
            onMediaReady: onMediaReady
        )
    }

    private func bootstrapFocusedStaticThenLive(
        focused: Card,
        focusedIndex: Int,
        cards: [Card],
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        if focusedCaptureTask != nil,
           let inFlight = focusedCaptureInFlight,
           inFlight.cardID == focused.id,
           inFlight.provider == provider {
            return
        }

        focusedCaptureTask?.cancel()
        assignLiveToFocused(cards: cards, focusedIndex: focusedIndex)
        markStackRevealed(
            cards: cards,
            focusedIndex: focusedIndex,
            provider: provider,
            allowWithoutSnapshot: true
        )
        focusedCaptureInFlight = (focused.id, provider)
        let camera = cameraStore.frame(for: focused.id)

        focusedCaptureTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if let inFlight = self.focusedCaptureInFlight,
                   inFlight.cardID == focused.id, inFlight.provider == provider {
                    self.focusedCaptureInFlight = nil
                }
            }

            await self.snapshotController.ensureStaticSnapshot(
                for: focused,
                size: self.mapContentSize,
                provider: provider,
                priority: MapSnapshotCapturePolicy.bootstrapPeekPriority,
                cameraFrame: camera,
                onLoadingChanged: { loading in
                    self.setMapLoadingIfStackVisible(loading, cardID: focused.id)
                }
            )

            guard !Task.isCancelled else { return }
            guard !self.isSnapshotBootstrapping else { return }
            guard cards.indices.contains(focusedIndex) else { return }

            self.revealFocusedAndGoLive(
                cards: cards,
                focusedIndex: focusedIndex,
                provider: provider,
                onMediaReady: onMediaReady
            )
        }
    }

    private func captureFocusedStaticInBackground(
        focused: Card,
        focusedIndex: Int,
        cards: [Card],
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        if shouldDeferFocusedBackgroundPeek(for: focused, provider: provider) {
            return
        }
        if focusedCaptureTask != nil,
           let inFlight = focusedCaptureInFlight,
           inFlight.cardID == focused.id,
           inFlight.provider == provider {
            return
        }

        focusedCaptureTask?.cancel()
        focusedCaptureInFlight = (focused.id, provider)
        let camera = cameraStore.frame(for: focused.id)

        focusedCaptureTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if let inFlight = self.focusedCaptureInFlight,
                   inFlight.cardID == focused.id, inFlight.provider == provider {
                    self.focusedCaptureInFlight = nil
                }
            }

            await self.snapshotController.ensureStaticSnapshot(
                for: focused,
                size: self.mapContentSize,
                provider: provider,
                priority: MapSnapshotCapturePolicy.bootstrapPeekPriority,
                cameraFrame: camera,
                onLoadingChanged: { loading in
                    self.setMapLoadingIfStackVisible(loading, cardID: focused.id)
                }
            )

            guard !Task.isCancelled else { return }
            guard !self.isSnapshotBootstrapping else { return }
            guard cards.indices.contains(focusedIndex) else { return }
            self.markStackRevealed(cards: cards, focusedIndex: focusedIndex, provider: provider)
            onMediaReady(focusedIndex)
        }
    }

    private func captureStaticSnapshots(
        at indices: [Int],
        cards: [Card],
        provider: MapProviderId,
        onMediaReady: @escaping (Int) -> Void
    ) {
        guard !indices.isEmpty else { return }
        if visibleStaticCaptureTask != nil, visibleStaticCaptureInFlight == indices {
            return
        }

        visibleStaticCaptureTask?.cancel()
        visibleStaticCaptureInFlight = indices
        visibleStaticCaptureTask = Task { [weak self] in
            guard let self else { return }
            defer { self.visibleStaticCaptureInFlight = nil }
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
                if self.cardHasStaticSnapshot(card, provider: provider) {
                    onMediaReady(index)
                }
            }
        }
    }

    private func markStackRevealed(
        cards: [Card],
        focusedIndex: Int,
        provider: MapProviderId,
        allowWithoutSnapshot: Bool = false
    ) {
        guard cards.indices.contains(focusedIndex) else { return }
        let focused = cards[focusedIndex]
        let hasStatic = cardHasStaticSnapshot(focused, provider: provider)
            || focused.frozenSnapshot(for: provider) != nil
        guard hasStatic || allowWithoutSnapshot else { return }
        hasRevealedCardStack = true
    }
}

#if os(iOS)
public extension GeoKitCenterCardMediaStore {
    convenience init(cameraStore: MapCameraStore) {
        self.init(cameraStore: cameraStore, snapshotController: GeoKitCardMapMediaController.shared)
    }

    var mapMediaController: GeoKitCardMapMediaController { GeoKitCardMapMediaController.shared }

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
