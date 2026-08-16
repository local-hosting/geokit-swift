import GeoKitContract
import GeoKitUI
import XCTest

@MainActor
final class MapLocalStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let suite = "GeoKitMapLocalStoreTests"
        UserDefaults().removePersistentDomain(forName: suite)
        MapLocalStore.resetForTesting()
    }

    func testPersistsCameraFrame() {
        let defaults = UserDefaults(suiteName: "GeoKitMapLocalStoreTests")!
        let store = MapLocalStore(defaults: defaults)
        let camera = MapCameraFrame(
            centerLatitude: 40.75,
            centerLongitude: -73.98,
            zoom: 12,
            bearing: 0,
            pitch: 0
        )
        store.patch(mapID: "card-1", cameraFrame: camera)
        let reloaded = MapLocalStore(defaults: defaults)
        XCTAssertEqual(reloaded.state(for: "card-1")?.cameraFrame, camera)
    }

    func testPersistsSelectedPinId() {
        let defaults = UserDefaults(suiteName: "GeoKitMapLocalStoreTests")!
        let store = MapLocalStore(defaults: defaults)
        let pinId = UUID()
        store.patch(mapID: "card-2", selectedPinId: .some(pinId))
        XCTAssertEqual(store.state(for: "card-2")?.selectedPinId, pinId)
    }
}
