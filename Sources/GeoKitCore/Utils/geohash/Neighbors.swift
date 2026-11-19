import Foundation

/// Mirrors `geokit/src/core/src/utils/geohash/neighbors.ts`.

public func geohashNeighbors(_ hash: String) throws -> GeohashNeighbors {
    try Geohash.neighbors(hash)
}

public func geohashNeighborsArray(_ hash: String) throws -> [String] {
    try Geohash.neighborsArray(hash)
}

public func geohashNeighbor(_ hash: String, direction: Geohash.CardinalDirection) throws -> String {
    try Geohash.neighbor(hash, direction: direction)
}