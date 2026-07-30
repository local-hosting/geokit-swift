import GeoKitContract
import XCTest

@MainActor
final class GeoKitLiveCameraCacheCollapseTests: XCTestCase {
    private final class StoreStub: GeoKitLiveCameraStoreWriting {
        var frames: [String: MapCameraFrame] = [:]

        func setLiveCameraFrame(_ frame: MapCameraFrame, for mapID: String) {
            frames[mapID] = frame
        }

        func frame(for mapID: String) -> MapCameraFrame? {
            frames[mapID]
        }
    }

    override func tearDown() {
        GeoKitLiveCameraCache.removeAll()
        super.tearDown()
    }

    func testLiveCacheWinsOverStaleStoreOnFlush() {
        let previous = MapCameraFrame(
            centerLatitude: 30.2672,
            centerLongitude: -97.7431,
            zoom: 12,
            bearing: 0,
            pitch: 0
        )
        let current = MapCameraFrame(
            centerLatitude: 30.3,
            centerLongitude: -97.8,
            zoom: 14,
            bearing: 20,
            pitch: 10
        )
        let store = StoreStub()
        store.setLiveCameraFrame(previous, for: "city-lights")
        GeoKitLiveCameraCache.note(current, for: "city-lights")

        let flushed = GeoKitLiveCameraCache.flush(into: store, mapID: "city-lights")

        XCTAssertEqual(flushed, current)
        XCTAssertEqual(store.frame(for: "city-lights"), current)
        XCTAssertFalse(previous.isApproximatelyEqual(to: current))
    }
}
