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

        let frame = MapCameraFrameResolver.resolve(for: request)
        XCTAssertEqual(frame.centerLatitude, camera.centerLatitude)
        XCTAssertEqual(frame.centerLongitude, camera.centerLongitude)
        XCTAssertEqual(frame.zoom, camera.zoom)
        XCTAssertEqual(frame.bearing, camera.bearing)
        XCTAssertEqual(frame.pitch, MapCameraFrameResolver.collapsedPitch)
    }


    func testRejectsStoredFrameFarFromPinAnchor() {
        let montreal = MapCameraFrame(
            centerLatitude: 45.4295,
            centerLongitude: -73.5534,
            zoom: 12,
            bearing: 0,
            pitch: MapCameraFrameResolver.defaultPitch
        )
        XCTAssertNil(MapCameraFrameResolver.storedFrameIfNearPins(montreal, pins: [pin]))
    }

    func testResolveIgnoresStaleStoredCameraOnRequest() {
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
        XCTAssertEqual(frame.centerLatitude, pin.latitude, accuracy: 0.0001)
        XCTAssertEqual(frame.centerLongitude, pin.longitude, accuracy: 0.0001)
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
}
