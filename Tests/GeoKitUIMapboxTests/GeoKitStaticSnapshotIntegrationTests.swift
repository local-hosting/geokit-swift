#if os(iOS)
import GeoKitContract
import GeoKitUI
import GeoKitUIMapbox
import MapboxMaps
import UIKit
import XCTest

@MainActor
final class GeoKitStaticSnapshotIntegrationTests: XCTestCase {
    private let demoStyleURI = "mapbox://styles/mapbox/streets-v12"
    private let demoToken = "REDACTED_MAPBOX_TOKEN"

    override func setUp() {
        super.setUp()
        GeoKitUIMapboxRegistration.activate()
        MapboxOptions.accessToken = demoToken
    }

    func testMapboxStaticSnapshotCaptureProducesPeekCover() async throws {
        let request = MapContentRequest(
            id: "nyc-map",
            phase: .snapshot,
            isExpanded: false,
            title: "New York City",
            mapStyleURI: demoStyleURI,
            preferredZoom: 11,
            pins: [
                MapPin(
                    id: UUID(uuidString: "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1")!,
                    latitude: 40.7128,
                    longitude: -74.0060,
                    pinHeading: "City Hall",
                    pinSubheading: "NYC",
                    icon: "building.2",
                    isPrimary: true
                ),
            ],
            showUserPuck: false,
            mapProviderId: .mapbox,
            cameraFrame: MapCameraFrame(
                centerLatitude: 40.7128,
                centerLongitude: -74.0060,
                zoom: 11,
                bearing: 0,
                pitch: 0
            ),
            selectedPinId: nil
        )

        let image = try await GeoKitCardSnapshotCapture.capture(
            request: request,
            size: CGSize(width: 320, height: 400),
            priority: .background
        )

        XCTAssertNotNil(image)
        XCTAssertTrue(
            GeoKitMapSnapshotContentPolicy.acceptsPersistedMapBitmap(image!),
            "Mapbox Static Images response must pass peek cover validation"
        )
    }
}
#endif
