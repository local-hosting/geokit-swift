import CoreGraphics
import GeoKitContract
import XCTest

final class MapSurfaceMountPolicyTests: XCTestCase {
    func testValidLayoutSizeRequires128Points() {
        XCTAssertTrue(MapSurfaceMountPolicy.isValidLayoutSize(CGSize(width: 128, height: 128)))
        XCTAssertTrue(MapSurfaceMountPolicy.isValidLayoutSize(CGSize(width: 400, height: 300)))
        XCTAssertFalse(MapSurfaceMountPolicy.isValidLayoutSize(CGSize(width: 127, height: 300)))
        XCTAssertFalse(MapSurfaceMountPolicy.isValidLayoutSize(CGSize(width: 300, height: 0)))
    }

    func testCanMountMapRequiresSurfaceReadyAndValidSize() {
        let valid = CGSize(width: 200, height: 200)
        XCTAssertTrue(MapSurfaceMountPolicy.canMountMap(surfaceReady: true, layoutSize: valid))
        XCTAssertFalse(MapSurfaceMountPolicy.canMountMap(surfaceReady: false, layoutSize: valid))
        XCTAssertFalse(MapSurfaceMountPolicy.canMountMap(surfaceReady: true, layoutSize: CGSize(width: 64, height: 64)))
    }

    func testShouldShowLiveMapRequiresMountAndReadyFlag() {
        XCTAssertTrue(MapSurfaceMountPolicy.shouldShowLiveMap(canMount: true, mapReady: true))
        XCTAssertFalse(MapSurfaceMountPolicy.shouldShowLiveMap(canMount: true, mapReady: false))
        XCTAssertFalse(MapSurfaceMountPolicy.shouldShowLiveMap(canMount: false, mapReady: true))
    }

    func testSnapshotCaptureSkippedWhenLayoutTooSmall() {
        XCTAssertFalse(MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: CGSize(width: 100, height: 200)))
        XCTAssertTrue(MapSurfaceMountPolicy.shouldBeginSnapshotCapture(layoutSize: CGSize(width: 200, height: 200)))
    }
}
