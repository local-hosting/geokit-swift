import GeoKitContract
import XCTest

final class MapSnapshotCaptureExecutorTests: XCTestCase {
    private enum TestError: Error {
        case captureFailed
    }

    func testExecutorRetriesUntilMaxAttempts() async throws {
        var attempts = 0
        let result = try await MapSnapshotCaptureExecutor.captureWithRetry {
            attempts += 1
            return Optional<String>.none
        }
        XCTAssertNil(result)
        XCTAssertEqual(attempts, MapSnapshotCapturePolicy.maxAttempts)
    }

    func testExecutorReturnsFirstSuccessfulCapture() async throws {
        var attempts = 0
        let result = try await MapSnapshotCaptureExecutor.captureWithRetry {
            attempts += 1
            return attempts == 1 ? nil : "ok"
        }
        XCTAssertEqual(result, "ok")
        XCTAssertEqual(attempts, 2)
    }

    func testExecutorDoesNotRetryThrownErrors() async throws {
        var attempts = 0
        do {
            _ = try await MapSnapshotCaptureExecutor.captureWithRetry {
                attempts += 1
                throw TestError.captureFailed
            }
            XCTFail("expected capture to throw")
        } catch TestError.captureFailed {
            XCTAssertEqual(attempts, 1)
        }
    }
}
