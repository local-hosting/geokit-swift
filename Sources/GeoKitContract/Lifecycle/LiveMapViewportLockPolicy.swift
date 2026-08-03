import Foundation

public enum LiveMapViewportLockPolicy {
    public static func shouldApplyDeclaredCameraRetarget(locksLiveViewport: Bool) -> Bool {
        !locksLiveViewport
    }
}
