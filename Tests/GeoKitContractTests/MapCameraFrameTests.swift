import GeoKitContract
import XCTest

final class MapCameraFrameTests: XCTestCase {
    func testMapContentRequestCarriesOptionalCameraFrame() {
        let frame = MapCameraFrame(
            centerLatitude: 40.7128,
            centerLongitude: -74.006,
            zoom: 14.5,
            bearing: 30,
            pitch: 50
        )
        let request = MapContentRequest(
            id: "nyc",
            phase: .live,
            isExpanded: true,
            cameraFrame: frame
        )
        XCTAssertEqual(request.cameraFrame, frame)
    }
}
