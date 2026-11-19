import Foundation

/// Shared lifecycle constants aligned with Node `@local-hosting/geokit/ui` map-freeze and placeholder helpers.
public enum GeoKitMapLifecycleConstants {
    public static let stuckPlaceholderMs: TimeInterval = 10
    public static let webGLContextsPerMap = 2
    public static let webGLContextBudget = 8
    public static let defaultStyleReadyTimeoutMs: TimeInterval = 2
    public static let defaultMapReadyTimeoutMs: TimeInterval = 10
    public static let defaultWebGLReleaseDelayMs: TimeInterval = 0.1

    public static func maxActiveMaps(requestedPoolSize: Int) -> Int {
        let budgetCap = max(1, webGLContextBudget / webGLContextsPerMap)
        return min(max(1, requestedPoolSize), budgetCap)
    }
}
