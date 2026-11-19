import Foundation

/// Mirrors `geokit/src/core/src/utils/geohash/bounds.ts`.

public func geohashBounds(_ hash: String) throws -> Bounds {
    try Geohash.bounds(hash)
}