import Foundation

/// Mirrors `geokit/src/core/src/utils/geohash/encode.ts`.

public func encodeGeohash(precision: Int = 10) -> (LatLon) -> String {
    { coordinate in Geohash.encode(coordinate, precision: precision) }
}

public func encodeGeohash(_ coordinate: LatLon, precision: Int = 10) -> String {
    Geohash.encode(coordinate, precision: precision)
}