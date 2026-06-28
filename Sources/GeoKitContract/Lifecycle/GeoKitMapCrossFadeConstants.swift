import Foundation

/// Snapshot → live map opacity handoff (card slot + Mapbox surface).
public enum GeoKitMapCrossFadeConstants {
    /// Base cross-fade before ``animationSpeed`` scaling (was ~0.3s).
    public static let baseDuration: TimeInterval = 0.55

    public static func scaledDuration(
        animationSpeed: Double,
        base: TimeInterval = baseDuration
    ) -> TimeInterval {
        base / max(animationSpeed, 0.1)
    }
}
