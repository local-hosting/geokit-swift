#if canImport(UIKit)
import UIKit
import XCTest
import GeoKitUI

final class GeoKitMapSnapshotContentPolicyTests: XCTestCase {
    func testAcceptsPersistedMapBitmap_acceptsDarkNightStyleMap() {
        let image = darkNightStyleMapSnapshot()
        XCTAssertTrue(GeoKitMapSnapshotContentPolicy.acceptsPersistedMapBitmap(image))
        XCTAssertTrue(
            GeoKitMapSnapshotContentPolicy.acceptsCapturedBitmap(image, fromStaticImageService: true)
        )
    }

    func testAcceptsPersistedMapBitmap_rejectsUniformBlankPlate() {
        let image = uniformColorSnapshot(.black)
        XCTAssertFalse(GeoKitMapSnapshotContentPolicy.acceptsPersistedMapBitmap(image))
        XCTAssertFalse(GeoKitMapSnapshotContentPolicy.hasVisibleMapContent(image))
    }

    func testHasVisibleMapContent_acceptsColorfulGPUStyleCapture() {
        let image = colorfulMapSnapshot()
        XCTAssertTrue(GeoKitMapSnapshotContentPolicy.hasVisibleMapContent(image))
        XCTAssertTrue(GeoKitMapSnapshotContentPolicy.acceptsPersistedMapBitmap(image))
    }
}

private func darkNightStyleMapSnapshot() -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 320, height: 480)).image { context in
        UIColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: 0, width: 320, height: 240))
        UIColor(red: 0.18, green: 0.2, blue: 0.28, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: 240, width: 320, height: 240))
    }
}

private func uniformColorSnapshot(_ color: UIColor) -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 120, height: 160)).image { context in
        color.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 120, height: 160))
    }
}

private func colorfulMapSnapshot() -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 120, height: 160)).image { context in
        UIColor.systemOrange.setFill()
        context.fill(CGRect(origin: .zero, size: CGSize(width: 120, height: 160)))
        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 40, y: 40, width: 40, height: 40))
    }
}
#endif
