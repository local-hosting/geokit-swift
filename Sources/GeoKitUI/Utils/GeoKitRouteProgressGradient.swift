import Foundation
import GeoKitCore

public struct GeoKitRouteProgressGradientOptions: Sendable, Equatable {
    public let color: String
    public let progress: Double
    public let trailOpacity: Double
    public let aheadOpacity: Double
    public let progressOffset: Double

    public init(
        color: String,
        progress: Double,
        trailOpacity: Double = 0.55,
        aheadOpacity: Double = 0.35,
        progressOffset: Double = 0.005
    ) {
        self.color = color
        self.progress = progress
        self.trailOpacity = trailOpacity
        self.aheadOpacity = aheadOpacity
        self.progressOffset = progressOffset
    }
}

public enum GeoKitRouteProgressGradient {
    /// Build a MapLibre-style `line-gradient` expression for route progress highlighting.
    public static func expression(options: GeoKitRouteProgressGradientOptions) -> [Any] {
        let rgb = GeoKitColor.hexToRGB(options.color)
        let adjustedProgress = max(0, min(1, options.progress - options.progressOffset))

        return [
            "step",
            ["line-progress"],
            "rgba(\(rgb.r), \(rgb.g), \(rgb.b), \(options.trailOpacity))",
            adjustedProgress,
            "rgba(\(rgb.r), \(rgb.g), \(rgb.b), \(options.aheadOpacity))",
        ]
    }
}
