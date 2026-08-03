import GeoKitContract
import XCTest

final class LiveMapViewportLockPolicyTests: XCTestCase {
    func testSkipsDeclaredRetargetWhenLiveViewportLocked() {
        XCTAssertFalse(
            LiveMapViewportLockPolicy.shouldApplyDeclaredCameraRetarget(locksLiveViewport: true)
        )
    }

    func testAppliesDeclaredRetargetBeforeLiveLock() {
        XCTAssertTrue(
            LiveMapViewportLockPolicy.shouldApplyDeclaredCameraRetarget(locksLiveViewport: false)
        )
    }
}
