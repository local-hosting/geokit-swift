import GeoKitContract
import XCTest

final class MapboxStaticImageCameraLimitsTests: XCTestCase {
    func testClampsPitchAboveSixty() {
        let frame = MapCameraFrame(
            centerLatitude: -16.5,
            centerLongitude: -151.7,
            zoom: 12,
            bearing: 30,
            pitch: 70
        )
        let clamped = MapboxStaticImageCameraLimits.clamped(forStaticImages: frame)
        XCTAssertEqual(clamped.pitch, 60, accuracy: 0.001)
        XCTAssertEqual(clamped.bearing, 30, accuracy: 0.001)
        XCTAssertEqual(clamped.centerLatitude, frame.centerLatitude, accuracy: 0.0001)
        XCTAssertEqual(clamped.zoom, frame.zoom, accuracy: 0.01)
    }

    func testNormalizesNegativeBearing() {
        let frame = MapCameraFrame(
            centerLatitude: 0,
            centerLongitude: 0,
            zoom: 8,
            bearing: -45,
            pitch: 10
        )
        let clamped = MapboxStaticImageCameraLimits.clamped(forStaticImages: frame)
        XCTAssertEqual(clamped.bearing, 315, accuracy: 0.001)
        XCTAssertEqual(clamped.pitch, 10, accuracy: 0.001)
    }

    func testClampsNegativePitchToZero() {
        let frame = MapCameraFrame(
            centerLatitude: 1,
            centerLongitude: 2,
            zoom: 9,
            bearing: 400,
            pitch: -5
        )
        let clamped = MapboxStaticImageCameraLimits.clamped(forStaticImages: frame)
        XCTAssertEqual(clamped.pitch, 0, accuracy: 0.001)
        XCTAssertEqual(clamped.bearing, 40, accuracy: 0.001)
    }
}
