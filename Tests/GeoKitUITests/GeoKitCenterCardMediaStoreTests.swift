#if canImport(UIKit) || canImport(AppKit)
import CoreGraphics
import GeoKitContract
import XCTest
@testable import GeoKitUI

@MainActor
final class GeoKitCenterCardMediaStoreTests: XCTestCase {
    private let provider: MapProviderId = .mapbox
    private let layoutSize = CGSize(width: 400, height: 400)

    private func makeStore(
        cardCount: Int
    ) -> (GeoKitCenterCardMediaStore<FakeSnapshotCard>, FakeSnapshotController, [FakeSnapshotCard]) {
        let controller = FakeSnapshotController()
        let store = GeoKitCenterCardMediaStore<FakeSnapshotCard>(
            cameraStore: MapCameraStore(defaults: .standard, keyPrefix: "test.\(UUID().uuidString)."),
            snapshotController: controller
        )
        store.updateMapContentSize(layoutSize)
        let cards = (0..<cardCount).map { FakeSnapshotCard(id: "card-\($0)") }
        return (store, controller, cards)
    }


    func test_dragWarmLiveBeginAndEnd() {
        let (store, _, cards) = makeStore(cardCount: 3)
        store.beginDragWarmLive(cardID: cards[1].id)
        XCTAssertEqual(store.warmLiveCardID, cards[1].id)
        XCTAssertTrue(store.isLiveEnabled(for: cards[1].id))
        store.endDragWarmLive()
        XCTAssertNil(store.warmLiveCardID)
    }

    func test_commitDragWarmHandoffPromotesWarmToLive() {
        let (store, _, cards) = makeStore(cardCount: 3)
        var rotated = cards
        let backCard = rotated.removeLast()
        rotated.insert(backCard, at: 0)
        store.beginDragWarmLive(cardID: backCard.id)
        store.commitDragWarmHandoff(cards: rotated, centerIndex: 0)
        XCTAssertNil(store.warmLiveCardID)
        XCTAssertEqual(store.liveCardID, backCard.id)
    }

    func test_liveRenderedCenterWithoutSnapshotKeepsLiveDuringRefresh() async {
        let controller = FakeSnapshotController()
        let store = GeoKitCenterCardMediaStore<FakeLiveSnapshotCard>(
            cameraStore: MapCameraStore(defaults: .standard, keyPrefix: "test.\(UUID().uuidString)."),
            snapshotController: controller
        )
        store.updateMapContentSize(layoutSize)
        let cards = (0..<3).map { FakeLiveSnapshotCard(id: "card-\($0)") }
        var rotated = cards
        let backCard = rotated.removeLast()
        rotated.insert(backCard, at: 0)
        backCard.setMapRendered(true, for: provider)
        store.beginDragWarmLive(cardID: backCard.id)
        store.commitDragWarmHandoff(cards: rotated, centerIndex: 0)

        store.refreshCenter(cards: rotated, centerIndex: 0, provider: provider, onMediaReady: { _ in })

        XCTAssertEqual(store.liveCardID, backCard.id, "live stays mounted while the HTTP peek runs")
        await settle()
        XCTAssertEqual(controller.captureCount(for: backCard.id), 1, "missing peek is captured in the background")
    }

    func test_capturesCenterBeforeLive() async {
        let (store, controller, cards) = makeStore(cardCount: 6)

        store.refreshCenter(cards: cards, centerIndex: 0, provider: provider, onMediaReady: { _ in })
        await settle()

        XCTAssertTrue(store.isInitialCenterPeekReady)
        XCTAssertTrue(store.hasRevealedCardStack)
        XCTAssertEqual(controller.captureOrder.first, cards[0].id, "center must be captured first")
        XCTAssertEqual(store.liveCardID, cards[0].id, "center goes live after its snapshot exists")
        XCTAssertEqual(controller.priorityByCard[cards[0].id], .background, "center bootstrap uses cheap static peek")
    }

    func test_cachedCenterRevealsStackImmediately() async {
        let (store, controller, cards) = makeStore(cardCount: 6)
        cards[0].setFrozenSnapshot(
            makeTestSnapshotImage(),
            for: provider,
            cameraFrame: MapCameraFrame(centerLatitude: 1, centerLongitude: 2, zoom: 12)
        )

        store.refreshCenter(cards: cards, centerIndex: 0, provider: provider, onMediaReady: { _ in })

        XCTAssertTrue(store.isInitialCenterPeekReady)
        XCTAssertTrue(store.hasRevealedCardStack)
        await settle()
        XCTAssertEqual(controller.captureCount(for: cards[0].id), 0)
    }

    func test_fanCaptureOrderIsSequentialFromCenterOutward() async {
        let (store, controller, cards) = makeStore(cardCount: 6)

        store.refreshCenter(cards: cards, centerIndex: 0, provider: provider, onMediaReady: { _ in })
        await settle()

        XCTAssertEqual(
            controller.captureOrder,
            cards.map(\.id),
            "center loads first, then fan slots in peek-distance order"
        )
    }

    func test_fanCapturedAfterCenter() async {
        let (store, controller, cards) = makeStore(cardCount: 6)

        store.refreshCenter(cards: cards, centerIndex: 0, provider: provider, onMediaReady: { _ in })
        await settle()

        XCTAssertEqual(controller.captureOrder.first, cards[0].id, "center precedes fan")
        let fanIDs = Set(cards[1...].map(\.id))
        let capturedFan = Set(controller.captureOrder.dropFirst())
        XCTAssertEqual(capturedFan, fanIDs, "all fan slots within peek radius are captured")
        for index in 1..<cards.count {
            XCTAssertEqual(controller.priorityByCard[cards[index].id], .background, "fan is background priority")
        }
    }

    func test_capturesEachCardOnce() async {
        let (store, controller, cards) = makeStore(cardCount: 6)

        store.refreshCenter(cards: cards, centerIndex: 0, provider: provider, onMediaReady: { _ in })
        await settle()
        store.refreshCenter(cards: cards, centerIndex: 0, provider: provider, onMediaReady: { _ in })
        await settle()

        for card in cards {
            XCTAssertEqual(controller.captureCount(for: card.id), 1, "no recapture when snapshot is cached")
        }
    }

    func test_cachedCenterSkipsCaptureAndGoesLiveImmediately() async {
        let (store, controller, cards) = makeStore(cardCount: 6)
        cards[0].setFrozenSnapshot(
            makeTestSnapshotImage(),
            for: provider,
            cameraFrame: MapCameraFrame(centerLatitude: 1, centerLongitude: 2, zoom: 12)
        )

        store.refreshCenter(cards: cards, centerIndex: 0, provider: provider, onMediaReady: { _ in })

        XCTAssertEqual(store.liveCardID, cards[0].id, "cached center goes live without awaiting capture")
        XCTAssertFalse(controller.captureOrder.contains(cards[0].id), "cached center is never recaptured")

        await settle()
        XCTAssertEqual(controller.captureCount(for: cards[0].id), 0, "center stays uncaptured")
    }

    func test_noopWhenLayoutNotReady() async {
        let controller = FakeSnapshotController()
        let store = GeoKitCenterCardMediaStore<FakeSnapshotCard>(
            cameraStore: MapCameraStore(defaults: .standard, keyPrefix: "test.\(UUID().uuidString)."),
            snapshotController: controller
        )
        let cards = (0..<6).map { FakeSnapshotCard(id: "card-\($0)") }

        store.refreshCenter(cards: cards, centerIndex: 0, provider: provider, onMediaReady: { _ in })
        await settle()

        XCTAssertTrue(controller.captureOrder.isEmpty, "no captures before a valid layout size")
        XCTAssertNil(store.liveCardID)
    }

    func test_prepareCardExpansionSuspendsLiveBeforeCapture() async {
        let (store, controller, cards) = makeStore(cardCount: 1)
        let card = cards[0]
        store.syncCenterLive(cards: cards, centerIndex: 0)
        XCTAssertEqual(store.liveCardID, card.id)

        store.prepareCardExpansion(
            card: card,
            provider: provider,
            mapSize: layoutSize,
            cameraFrame: nil
        ) {}

        await settle()

        XCTAssertEqual(controller.captureOrder, [card.id])
        XCTAssertEqual(controller.priorityByCard[card.id], .top)
    }

    func test_prepareCardExpansionCapturesThenCallsReady() async {
        let (store, controller, cards) = makeStore(cardCount: 1)
        let card = cards[0]
        var readyCalled = false

        XCTAssertFalse(store.isSnapshotBootstrapping)
        store.prepareCardExpansion(
            card: card,
            provider: provider,
            mapSize: layoutSize,
            cameraFrame: nil
        ) {
            readyCalled = true
        }

        await settle()

        XCTAssertTrue(readyCalled, "expand should start only after capture completes")
        XCTAssertEqual(controller.captureOrder, [card.id])
        XCTAssertEqual(controller.priorityByCard[card.id], .top, "expand peek uses GPU snapshot at full viewport")
        XCTAssertEqual(controller.matchesLiveViewportByCard[card.id], true)
        XCTAssertFalse(store.isSnapshotBootstrapping)
        XCTAssertTrue(card.hasUsableSnapshot(for: provider, cameraFrame: nil))
    }

    func test_refreshCenterSkipsWhileExpansionPrepareInFlight() async {
        let (store, controller, cards) = makeStore(cardCount: 1)
        var readyCalled = false

        store.prepareCardExpansion(
            card: cards[0],
            provider: provider,
            mapSize: layoutSize,
            cameraFrame: nil
        ) {
            readyCalled = true
        }

        store.refreshCenter(cards: cards, centerIndex: 0, provider: provider, onMediaReady: { _ in })

        await settle()

        XCTAssertTrue(readyCalled)
        XCTAssertEqual(controller.captureCount(for: cards[0].id), 1, "refreshCenter must not restart center capture during expand prep")
    }

    func test_prepareCardExpansionForceRecapturesWhenSnapshotAlreadyExists() async {
        let (store, controller, cards) = makeStore(cardCount: 1)
        let card = cards[0]
        let fullScreenSize = CGSize(width: layoutSize.width * 2, height: layoutSize.height * 2)

        card.setFrozenSnapshot(
            makeTestSnapshotImage(),
            for: provider,
            cameraFrame: MapCameraFrame(centerLatitude: 0, centerLongitude: 0, zoom: 10)
        )
        card.setMapSnapshotSize(layoutSize, for: provider)

        store.prepareCardExpansion(
            card: card,
            provider: provider,
            mapSize: layoutSize,
            expansionSnapshotSize: fullScreenSize,
            cameraFrame: nil
        ) {}
        await settle()
        XCTAssertEqual(controller.captureCount(for: card.id), 1)

        store.prepareCardExpansion(
            card: card,
            provider: provider,
            mapSize: layoutSize,
            expansionSnapshotSize: fullScreenSize,
            cameraFrame: nil
        ) {}
        await settle()
        XCTAssertEqual(
            controller.captureCount(for: card.id),
            2,
            "repeat expand must recapture the full-viewport peek even when a collapsed snapshot already exists"
        )
        XCTAssertEqual(card.mapSnapshotSize(for: provider), fullScreenSize)
    }
}
#endif
