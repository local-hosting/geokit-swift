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

        XCTAssertEqual(MapCameraFrameResolver.resolve(for: request), camera)
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
        XCTAssertEqual(frame.pitch, MapCameraFrameResolver.defaultPitch)
    }
}
