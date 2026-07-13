import Foundation

/// Snapshot → live map opacity handoff (card slot + Mapbox surface).
public enum GeoKitMapCrossFadeConstants {
    /// Base cross-fade before ``animationSpeed`` scaling — keep short so it does not outpace the App Store hero morph.
    public static let baseDuration: TimeInterval = 0.2

    public static func scaledDuration(
        animationSpeed: Double,
        base: TimeInterval = baseDuration
    ) -> TimeInterval {
        base / max(animationSpeed, 0.1)
    }
}
