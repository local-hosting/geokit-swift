import Foundation

/// Mirrors `geokit/src/core/src/utils/bounds/calculate-zoom.ts`.

public func calculateZoomFromBounds(_ bounds: Bounds) -> Double {
    BoundsCalculator.zoom(from: bounds)
}

public func calculateCenterAndZoom(from bounds: Bounds) -> CenterAndZoom? {
    BoundsCalculator.centerAndZoom(from: bounds)
}