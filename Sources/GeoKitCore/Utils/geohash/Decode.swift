import Foundation

/// Mirrors `geokit/src/core/src/utils/geohash/decode.ts`.

public func decodeGeohash(_ hash: String) throws -> LatLon {
    try Geohash.decode(hash)
}