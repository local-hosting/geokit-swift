import GeoKitContract
import XCTest

final class MapSnapshotCaptureExecutorTests: XCTestCase {
    func testExecutorRetriesUntilMaxAttempts() async {
        var attempts = 0
        let result = await MapSnapshotCaptureExecutor.captureWithRetry {
            attempts += 1
            return Optional<String>.none
        }
        XCTAssertNil(result)
        XCTAssertEqual(attempts, MapSnapshotCapturePolicy.maxAttempts)
    }

    func testExecutorReturnsFirstSuccessfulCapture() async {
        var attempts = 0
        let result = await MapSnapshotCaptureExecutor.captureWithRetry {
            attempts += 1
            return attempts == 1 ? nil : "ok"
        }
        XCTAssertEqual(result, "ok")
        XCTAssertEqual(attempts, 2)
    }
}
