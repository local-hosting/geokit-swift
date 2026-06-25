import Foundation
import GeoKitContract

/// UI lifecycle helpers aligned with Node `@geokit/ui` map-freeze and placeholder timing.
public enum GeoKitMapLifecycle {
    public static func delayForWebGLRelease(
        delay: Duration = .milliseconds(Int(GeoKitMapLifecycleConstants.defaultWebGLReleaseDelayMs * 1000))
    ) async {
        try? await Task.sleep(for: delay)
    }

    public static func waitForStyleReady(
        isReady: @escaping () -> Bool,
        timeout: Duration = .seconds(Int(GeoKitMapLifecycleConstants.defaultStyleReadyTimeoutMs))
    ) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if isReady() { return true }
            try? await Task.sleep(for: .milliseconds(16))
        }
        return isReady()
    }

    public static func stuckPlaceholderDuration() -> Duration {
        .seconds(Int(GeoKitMapLifecycleConstants.stuckPlaceholderMs))
    }
}
