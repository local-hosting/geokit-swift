import Foundation

/// Mirrors `geokit/src/core/src/utils/bounds/is-within-bounds.ts`.

public func isWithinBounds(_ bounds: Bounds, coordinate: LatLon) -> Bool {
    BoundsCalculator.isWithin(bounds, coordinate: coordinate)
}