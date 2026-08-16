import GeoKitContract
import XCTest

@MainActor
final class GeoKitLiveCameraCacheTests: XCTestCase {
    private final class StoreStub: GeoKitLiveCameraStoreWriting {
        var frames: [String: MapCameraFrame] = [:]

        func setLiveCameraFrame(_ frame: MapCameraFrame, for mapID: String) {
            frames[mapID] = frame
        }
    }

    override func tearDown() {
        GeoKitLiveCameraCache.removeAll()
        super.tearDown()
    }

    func testNoteAndFlushCopiesLiveFrameIntoStore() {
        let frame = MapCameraFrame(
            centerLatitude: -16.5,
            centerLongitude: -151.7,
            zoom: 11,
            bearing: 12,
            pitch: 20
        )
        GeoKitLiveCameraCache.note(frame, for: "bora-bora-map")

        let store = StoreStub()
        let flushed = GeoKitLiveCameraCache.flush(into: store, mapID: "bora-bora-map")

        XCTAssertEqual(flushed, frame)
        XCTAssertEqual(store.frames["bora-bora-map"], frame)
    }

    func testFlushReturnsNilWhenCacheEmpty() {
        let store = StoreStub()
        XCTAssertNil(GeoKitLiveCameraCache.flush(into: store, mapID: "missing"))
        XCTAssertTrue(store.frames.isEmpty)
    }
}
