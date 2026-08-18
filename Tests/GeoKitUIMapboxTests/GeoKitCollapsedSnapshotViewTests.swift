#if os(iOS)
import GeoKitContract
import GeoKitUI
import GeoKitUIMapbox
import MapboxMaps
import SwiftUI
import UIKit
import XCTest

@testable import GeoKitUIMapbox

@MainActor
final class GeoKitCollapsedSnapshotViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
        GeoKitUIRegistration.resetForTesting()
        GeoKitUIMapboxRegistration.resetForTesting()
        GeoKitCardSnapshotCaptureMapbox.testingBackgroundCapture = nil
    }

    override func tearDown() {
        GeoKitCardSnapshotCaptureMapbox.testingBackgroundCapture = nil
        GeoKitUIMapboxRegistration.resetForTesting()
        GeoKitUIRegistration.resetForTesting()
        super.tearDown()
    }

    func testPreloadedSnapshotPublishesGeoKitMapRenderedKey() {
        var mapRendered = false
        let host = GeoKitViewTestHost.collapsedSnapshot(
            request: GeoKitViewTestFixtures.snapshotRequest(),
            snapshot: GeoKitViewTestFixtures.validMapBitmap(),
            onMapRendered: { mapRendered = $0 }
        )
        host.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertTrue(mapRendered, "Preloaded snapshot must publish GeoKitMapRenderedKey")
    }

    func testBackgroundCaptureUpdatesSnapshotAndMapRenderedKey() async {
        GeoKitCardSnapshotCaptureMapbox.testingBackgroundCapture = { _, _ in
            GeoKitViewTestFixtures.validMapBitmap()
        }

        var mapRendered = false
        let host = GeoKitViewTestHost.collapsedSnapshot(
            request: GeoKitViewTestFixtures.snapshotRequest(),
            onMapRendered: { mapRendered = $0 }
        )
        host.layoutIfNeeded()

        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if mapRendered { break }
            await Task.yield()
            host.layoutIfNeeded()
        }

        XCTAssertTrue(mapRendered, "Background capture must publish GeoKitMapRenderedKey")
    }

    func testGeoKitMapContentSnapshotPhaseUsesCollapsedSnapshotView() async {
        GeoKitUIMapboxRegistration.activate()
        GeoKitCardSnapshotCaptureMapbox.testingBackgroundCapture = { _, _ in
            GeoKitViewTestFixtures.validMapBitmap()
        }

        var mapRendered = false
        let host = GeoKitViewTestHost.mapContent(
            request: GeoKitViewTestFixtures.snapshotRequest(),
            onMapRendered: { mapRendered = $0 }
        )
        host.layoutIfNeeded()

        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if mapRendered { break }
            await Task.yield()
            host.layoutIfNeeded()
        }

        XCTAssertTrue(mapRendered, "GeoKitMapContent snapshot phase must publish GeoKitMapRenderedKey")
    }
}

@MainActor
private enum GeoKitViewTestHost {
    static func collapsedSnapshot(
        request: MapContentRequest,
        snapshot: UIImage? = nil,
        onMapRendered: @escaping (Bool) -> Void
    ) -> GeoKitViewTestWindowHost {
        var storedSnapshot = snapshot
        let viewport = Binding<Viewport>(get: { .idle }, set: { _ in })
        let snapshotBinding = Binding<UIImage?>(
            get: { storedSnapshot },
            set: { storedSnapshot = $0 }
        )
        let root = GeoKitCollapsedSnapshotView(
            request: request,
            viewport: viewport,
            snapshot: snapshotBinding
        )
        .frame(width: 320, height: 400)
        .onPreferenceChange(GeoKitMapRenderedKey.self, perform: onMapRendered)

        return GeoKitViewTestWindowHost(rootView: root, size: CGSize(width: 320, height: 400))
    }

    static func mapContent(
        request: MapContentRequest,
        onMapRendered: @escaping (Bool) -> Void
    ) -> GeoKitViewTestWindowHost {
        let root = GeoKitMapContent(request: request)
            .frame(width: 320, height: 400)
            .onPreferenceChange(GeoKitMapRenderedKey.self, perform: onMapRendered)

        return GeoKitViewTestWindowHost(rootView: root, size: CGSize(width: 320, height: 400))
    }
}

@MainActor
private final class GeoKitViewTestWindowHost {
    let window: UIWindow
    let host: UIHostingController<AnyView>

    init<Content: View>(rootView: Content, size: CGSize) {
        host = UIHostingController(rootView: AnyView(rootView))
        host.view.frame = CGRect(origin: .zero, size: size)
        window = UIWindow(frame: host.view.frame)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
    }

    func layoutIfNeeded() {
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
    }
}

@MainActor
private enum GeoKitViewTestFixtures {
    static let demoStyleURI = "mapbox://styles/mapbox/streets-v12"

    static func snapshotRequest() -> MapContentRequest {
        MapContentRequest(
            id: "city-lights",
            phase: .snapshot,
            isExpanded: false,
            title: "New York City",
            mapStyleURI: demoStyleURI,
            preferredZoom: 11,
            pins: [],
            showUserPuck: false,
            mapProviderId: .mapbox,
            cameraFrame: MapCameraFrame(
                centerLatitude: 40.7128,
                centerLongitude: -74.0060,
                zoom: 11,
                bearing: 0,
                pitch: 0
            ),
            selectedPinId: nil,
            snapshotPriority: .background
        )
    }

    static func validMapBitmap() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 320, height: 400)).image { context in
            UIColor(red: 0.08, green: 0.09, blue: 0.15, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 320, height: 400)))
            UIColor(red: 0.85, green: 0.82, blue: 0.55, alpha: 1).setFill()
            context.fill(CGRect(x: 80, y: 120, width: 48, height: 48))
            UIColor(red: 0.35, green: 0.55, blue: 0.75, alpha: 1).setFill()
            context.fill(CGRect(x: 180, y: 200, width: 36, height: 36))
        }
    }
}
#endif
