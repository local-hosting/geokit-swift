import CoreGraphics
import GeoKitContract
import XCTest

@MainActor
final class GeoKitMapSnapshotCoordinatorTests: XCTestCase {
    private let size = CGSize(width: 256, height: 256)

    private func request(id: String, provider: MapProviderId) -> MapContentRequest {
        MapContentRequest(
            id: id,
            phase: .snapshot,
            isExpanded: false,
            mapProviderId: provider
        )
    }

    func testMapboxDefersCaptureWhileLiveMapActive() {
        let coordinator = GeoKitMapSnapshotCoordinator()
        coordinator.captureHandler = { _, _ in true }
        coordinator.schedule(request: request(id: "a", provider: .mapbox), size: size, liveMapActive: true)
        XCTAssertEqual(coordinator.pendingCaptures.count, 1)
        XCTAssertEqual(coordinator.completedCaptureCount, 0)
    }

    func testAppleCapturesImmediatelyWhileLiveMapActive() async {
        let coordinator = GeoKitMapSnapshotCoordinator()
        coordinator.captureHandler = { _, _ in true }
        coordinator.schedule(request: request(id: "b", provider: .apple), size: size, liveMapActive: true)
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertTrue(coordinator.pendingCaptures.isEmpty)
        XCTAssertEqual(coordinator.completedCaptureCount, 1)
    }

    func testFlushPendingRunsAfterLiveMapUnmounts() async {
        let coordinator = GeoKitMapSnapshotCoordinator()
        coordinator.captureHandler = { _, _ in true }
        coordinator.schedule(request: request(id: "c", provider: .mapbox), size: size, liveMapActive: true)
        XCTAssertEqual(coordinator.pendingCaptures.count, 1)
        await coordinator.flushPending(liveMapActive: false)
        XCTAssertTrue(coordinator.pendingCaptures.isEmpty)
        XCTAssertEqual(coordinator.completedCaptureCount, 1)
    }

    func testFlushPendingNoOpsWhileLiveMapStillActive() async {
        let coordinator = GeoKitMapSnapshotCoordinator()
        coordinator.captureHandler = { _, _ in true }
        coordinator.schedule(request: request(id: "d", provider: .mapbox), size: size, liveMapActive: true)
        await coordinator.flushPending(liveMapActive: true)
        XCTAssertEqual(coordinator.pendingCaptures.count, 1)
        XCTAssertEqual(coordinator.completedCaptureCount, 0)
    }
}
