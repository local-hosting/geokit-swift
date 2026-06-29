import CoreGraphics
import GeoKitContract
import XCTest

final class MapSnapshotStalenessPolicyTests: XCTestCase {
    private let pin = MapPin(
        id: UUID(uuidString: "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1")!,
        latitude: 40.7128,
        longitude: -74.006,
        pinHeading: "City Hall",
        pinSubheading: "NYC",
        icon: "building.2",
        isPrimary: true
    )

    private func request(selectedPinId: UUID? = nil) -> MapContentRequest {
        MapContentRequest(
            id: "city-lights",
            phase: .snapshot,
            isExpanded: false,
            mapStyleURI: "mapbox://styles/corio/test",
            preferredZoom: 12,
            pins: [pin],
            selectedPinId: selectedPinId
        )
    }

    private let layout = CGSize(width: 320, height: 480)

    func testMissingMetadataIsStale() {
        XCTAssertTrue(MapSnapshotStalenessPolicy.isStale(stored: nil, request: request(), layoutSize: layout))
    }

    func testMatchingMetadataIsFresh() {
        let request = request()
        let metadata = MapSnapshotStalenessPolicy.metadata(for: request, layoutSize: layout)
        XCTAssertFalse(MapSnapshotStalenessPolicy.isStale(stored: metadata, request: request, layoutSize: layout))
    }

    func testPitchChangeIsStale() {
        let request = request()
        var metadata = MapSnapshotStalenessPolicy.metadata(for: request, layoutSize: layout)
        metadata.cameraFrame.pitch = MapCameraFrameResolver.expandedPitch
        XCTAssertTrue(MapSnapshotStalenessPolicy.isStale(stored: metadata, request: request, layoutSize: layout))
    }

    func testPinMoveIsStale() {
        let request = request()
        let metadata = MapSnapshotStalenessPolicy.metadata(for: request, layoutSize: layout)
        var movedPin = pin
        movedPin.latitude += 0.01
        let movedRequest = MapContentRequest(
            id: request.id,
            phase: request.phase,
            isExpanded: request.isExpanded,
            mapStyleURI: request.mapStyleURI,
            preferredZoom: request.preferredZoom,
            pins: [movedPin],
            selectedPinId: request.selectedPinId
        )
        XCTAssertTrue(MapSnapshotStalenessPolicy.isStale(stored: metadata, request: movedRequest, layoutSize: layout))
    }

    func testLayoutResizeIsStale() {
        let request = request()
        let metadata = MapSnapshotStalenessPolicy.metadata(for: request, layoutSize: layout)
        let resized = CGSize(width: layout.width + 40, height: layout.height)
        XCTAssertTrue(MapSnapshotStalenessPolicy.isStale(stored: metadata, request: request, layoutSize: resized))
    }
}
