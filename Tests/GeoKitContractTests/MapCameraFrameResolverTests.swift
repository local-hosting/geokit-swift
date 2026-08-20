import GeoKitContract
import XCTest

final class MapCameraFrameResolverTests: XCTestCase {
    private let pin = MapPin(
        id: UUID(uuidString: "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1")!,
        latitude: 40.7128,
        longitude: -74.006,
        pinHeading: "NYC",
        pinSubheading: "",
        icon: "building.2",
        isPrimary: false
    )

    func testUsesRequestCameraWhenPresent() {
        let camera = MapCameraFrame(
            centerLatitude: 41,
            centerLongitude: -75,
            zoom: 14,
            bearing: 10,
            pitch: 45
        )
        let request = MapContentRequest(
            id: "nyc",
            phase: .live,
            isExpanded: false,
            preferredZoom: 12,
            pins: [pin],
            cameraFrame: camera
        )

        // The map is the map: the request camera is honored verbatim, including pitch and bearing.
        let frame = MapCameraFrameResolver.resolve(for: request)
        XCTAssertEqual(frame.centerLatitude, camera.centerLatitude)
        XCTAssertEqual(frame.centerLongitude, camera.centerLongitude)
        XCTAssertEqual(frame.zoom, camera.zoom)
        XCTAssertEqual(frame.bearing, camera.bearing)
        XCTAssertEqual(frame.pitch, camera.pitch)
    }


    func testResolveHonorsRequestCameraVerbatimEvenFarFromPins() {
        // The map is the map: a camera far from the pins (e.g. the user panned away) is still the real
        // camera and is returned as-is — never swapped for a pin-centered substitute.
        let montreal = MapCameraFrame(
            centerLatitude: 45.4295,
            centerLongitude: -73.5534,
            zoom: 12,
            bearing: 0,
            pitch: MapCameraFrameResolver.defaultPitch
        )
        let request = MapContentRequest(
            id: "nyc",
            phase: .live,
            isExpanded: true,
            preferredZoom: 12,
            pins: [pin],
            cameraFrame: montreal
        )
        let frame = MapCameraFrameResolver.resolve(for: request)
        XCTAssertEqual(frame.centerLatitude, montreal.centerLatitude, accuracy: 0.0001)
        XCTAssertEqual(frame.centerLongitude, montreal.centerLongitude, accuracy: 0.0001)
        XCTAssertEqual(frame.pitch, montreal.pitch, accuracy: 0.0001)
    }

    func testFallsBackToPinCenterWhenCameraMissing() {
        let request = MapContentRequest(
            id: "nyc",
            phase: .snapshot,
            isExpanded: false,
            preferredZoom: 12,
            pins: [pin]
        )

        let frame = MapCameraFrameResolver.resolve(for: request)
        XCTAssertEqual(frame.centerLatitude, pin.latitude, accuracy: 0.0001)
        XCTAssertEqual(frame.centerLongitude, pin.longitude, accuracy: 0.0001)
        XCTAssertEqual(frame.zoom, 12)
        XCTAssertEqual(frame.pitch, MapCameraFrameResolver.collapsedPitch)
    }

    func testCentersOnPinBoundingBoxMidpoint() {
        let second = MapPin(
            id: UUID(uuidString: "B2B2B2B2-B2B2-B2B2-B2B2-B2B2B2B2B2B2")!,
            latitude: 40.7628,
            longitude: -73.9740,
            pinHeading: "Midtown",
            pinSubheading: "",
            icon: "building.2",
            isPrimary: false
        )
        let request = MapContentRequest(
            id: "nyc",
            phase: .live,
            isExpanded: false,
            preferredZoom: 15,
            pins: [pin, second]
        )

        let frame = MapCameraFrameResolver.resolve(for: request)
        XCTAssertEqual(frame.centerLatitude, (pin.latitude + second.latitude) / 2, accuracy: 0.0001)
        XCTAssertEqual(frame.centerLongitude, (pin.longitude + second.longitude) / 2, accuracy: 0.0001)
        XCTAssertEqual(frame.zoom, 15)
    }

    func testCameraSettledOnlyWhenLiveCameraMatchesTarget() {
        let target = MapCameraFrame(
            centerLatitude: pin.latitude,
            centerLongitude: pin.longitude,
            zoom: 15,
            bearing: 0,
            pitch: 0
        )
        let atDefault = MapCameraFrame(
            centerLatitude: 0,
            centerLongitude: 0,
            zoom: 1,
            bearing: 0,
            pitch: 0
        )

        // Style default/world camera != target, so the cover holds through the fly-to.
        XCTAssertFalse(MapCameraFrameResolver.isCameraSettledAtTarget(atDefault, target: target))
        // Live camera has reached the target: settled.
        XCTAssertTrue(MapCameraFrameResolver.isCameraSettledAtTarget(target, target: target))
        // No camera reported yet: not settled.
        XCTAssertFalse(MapCameraFrameResolver.isCameraSettledAtTarget(nil, target: target))
    }

    func testExpandedInitialFrameUsesCollapsedPitchForTransitLabels() {
        let request = MapContentRequest(
            id: "nyc",
            phase: .live,
            isExpanded: true,
            preferredZoom: 12,
            pins: [pin]
        )
        let frame = MapCameraFrameResolver.resolve(for: request)
        XCTAssertEqual(frame.pitch, MapCameraFrameResolver.collapsedPitch)
    }
    func testIsNullIsland() {
        let nullIsland = MapCameraFrame(centerLatitude: 0, centerLongitude: 0, zoom: 12, bearing: 0, pitch: 0)
        let nyc = MapCameraFrame(centerLatitude: 40.7128, centerLongitude: -74.006, zoom: 12, bearing: 0, pitch: 0)
        XCTAssertTrue(MapCameraFrameResolver.isNullIsland(nullIsland))
        XCTAssertFalse(MapCameraFrameResolver.isNullIsland(nyc))
    }

    func testShouldDiscardStaleLiveCacheWhenPinsExist() {
        let live = MapCameraFrame(centerLatitude: 0, centerLongitude: 0, zoom: 15, bearing: 0, pitch: 0)
        let declared = MapCameraFrame(centerLatitude: 40.7527, centerLongitude: -73.9772, zoom: 15, bearing: 0, pitch: 0)
        XCTAssertTrue(
            MapCameraFrameResolver.shouldDiscardStaleLiveCache(live: live, declared: declared, pins: [pin])
        )
        XCTAssertFalse(
            MapCameraFrameResolver.shouldDiscardStaleLiveCache(live: live, declared: declared, pins: [])
        )
    }

    @MainActor
    func testResolveForCardSessionDiscardsNullIslandLiveCacheWhenPinsExist() {
        defer { GeoKitLiveCameraCache.remove(for: "nyc") }
        GeoKitLiveCameraCache.note(
            MapCameraFrame(centerLatitude: 0, centerLongitude: 0, zoom: 15, bearing: 0, pitch: 0),
            for: "nyc"
        )
        let declared = MapCameraFrame(
            centerLatitude: pin.latitude,
            centerLongitude: pin.longitude,
            zoom: 15,
            bearing: 0,
            pitch: 0
        )
        let frame = MapCameraFrameResolver.resolveForCardSession(
            mapID: "nyc",
            declared: declared,
            pins: [pin],
            isMapRendered: false
        )
        XCTAssertFalse(MapCameraFrameResolver.isNullIsland(frame))
        XCTAssertEqual(frame.centerLatitude, pin.latitude, accuracy: 0.0001)
    }

    @MainActor
    func testResolveForCardSessionUsesLiveCacheWhenMapRendered() {
        defer { GeoKitLiveCameraCache.remove(for: "nyc") }
        let livePan = MapCameraFrame(centerLatitude: 45.5, centerLongitude: -73.6, zoom: 14, bearing: 5, pitch: 10)
        GeoKitLiveCameraCache.note(livePan, for: "nyc")
        let declared = MapCameraFrame(
            centerLatitude: pin.latitude,
            centerLongitude: pin.longitude,
            zoom: 12,
            bearing: 0,
            pitch: 0
        )
        let frame = MapCameraFrameResolver.resolveForCardSession(
            mapID: "nyc",
            declared: declared,
            pins: [pin],
            isMapRendered: true
        )
        XCTAssertEqual(frame.centerLatitude, livePan.centerLatitude, accuracy: 0.0001)
        XCTAssertEqual(frame.bearing, livePan.bearing, accuracy: 0.01)
    }

}
