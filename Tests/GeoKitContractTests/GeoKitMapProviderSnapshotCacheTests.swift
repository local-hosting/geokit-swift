#if os(iOS)
import GeoKitContract
import UIKit
import XCTest

@MainActor
final class GeoKitMapProviderSnapshotCacheTests: XCTestCase {
    private let cameraA = MapCameraFrame(
        centerLatitude: 40.7128,
        centerLongitude: -74.006,
        zoom: 12
    )
    private let cameraB = MapCameraFrame(
        centerLatitude: 40.75,
        centerLongitude: -73.99,
        zoom: 13
    )

    func testStoresSnapshotsPerProviderIndependently() {
        let cache = GeoKitMapProviderSnapshotCache()
        let mapboxImage = UIImage()
        let appleImage = UIImage()

        cache.setSnapshot(mapboxImage, for: .mapbox, cameraFrame: cameraA)
        cache.setSnapshot(appleImage, for: .apple, cameraFrame: cameraA)

        XCTAssertTrue(cache.snapshot(for: .mapbox) === mapboxImage)
        XCTAssertTrue(cache.snapshot(for: .apple) === appleImage)
    }

    func testRemoveSnapshotForProviderDoesNotClearOtherProviders() {
        let cache = GeoKitMapProviderSnapshotCache()
        let mapboxImage = UIImage()
        cache.setSnapshot(mapboxImage, for: .mapbox, cameraFrame: cameraA)
        cache.setSnapshot(UIImage(), for: .apple, cameraFrame: cameraA)

        cache.removeSnapshot(for: .apple)

        XCTAssertTrue(cache.snapshot(for: .mapbox) === mapboxImage)
        XCTAssertNil(cache.snapshot(for: .apple))
    }

    func testSnapshotInvalidWhenSharedCameraMoves() {
        let cache = GeoKitMapProviderSnapshotCache()
        cache.setSnapshot(UIImage(), for: .mapbox, cameraFrame: cameraA)

        XCTAssertTrue(cache.isSnapshotCurrent(for: .mapbox, currentCamera: cameraA))
        XCTAssertFalse(cache.isSnapshotCurrent(for: .mapbox, currentCamera: cameraB))
    }

    func testSnapshotStillValidWithinApproximateTolerance() {
        let cache = GeoKitMapProviderSnapshotCache()
        cache.setSnapshot(UIImage(), for: .mapbox, cameraFrame: cameraA)
        let noisy = MapCameraFrame(
            centerLatitude: cameraA.centerLatitude + 0.000001,
            centerLongitude: cameraA.centerLongitude - 0.000001,
            zoom: cameraA.zoom + 0.01,
            bearing: cameraA.bearing + 0.1,
            pitch: cameraA.pitch + 0.1
        )

        XCTAssertTrue(cache.isSnapshotCurrent(for: .mapbox, currentCamera: noisy))
    }

    func testSnapshotValidBeforeUserCameraIsStored() {
        let cache = GeoKitMapProviderSnapshotCache()
        cache.setSnapshot(UIImage(), for: .apple, cameraFrame: cameraA)

        XCTAssertTrue(cache.isSnapshotCurrent(for: .apple, currentCamera: nil))
    }
}
#endif
