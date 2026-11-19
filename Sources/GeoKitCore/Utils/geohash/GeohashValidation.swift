import Foundation

/// Mirrors `geokit/src/core/src/utils/geohash/validation.ts`.

public func validateGeohash(_ hash: String) -> Bool {
    Geohash.isValid(hash)
}