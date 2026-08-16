#if os(iOS) || os(macOS)
import CoreGraphics
import GeoKitContract
import GeoKitUI
import XCTest
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class GeoKitMapSnapshotDiskStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testRoundTripsSnapshotPNG() throws {
        let store = GeoKitMapSnapshotDiskStore(fileManager: .default, directory: tempDirectory)
        let camera = MapCameraFrame(
            centerLatitude: 37.77,
            centerLongitude: -122.42,
            zoom: 11,
            bearing: 0,
            pitch: 0
        )
        let image = makeTestImage()
        try store.save(
            mapId: "trip-1",
            provider: .apple,
            image: image,
            cameraFrame: camera,
            selectedPinId: nil
        )
        let loaded = store.load(mapId: "trip-1", provider: .apple)
        XCTAssertNotNil(loaded?.image)
        XCTAssertEqual(loaded?.record.cameraFrame, camera)
    }

    private func makeTestImage() -> GeoKitPlatformImage {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        #elseif canImport(AppKit)
        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 4, height: 4).fill()
        image.unlockFocus()
        return image
        #endif
    }
}
#endif
