import Foundation

/// Mirrors `geokit/src/core/src/utils/interpolation/along-path.ts`.

public func interpolateAlongPath(fraction: Double, coordinates: [LatLon]) -> LatLon? {
    Interpolation.alongPath(fraction: fraction, coordinates: coordinates)
}

public func interpolateAlongPath(fraction: Double, lineString: GeoJSONLineString) -> LatLon? {
    Interpolation.alongPath(fraction: fraction, lineString: lineString)
}

public func interpolateAlongPath(fraction: Double, positions: [(Double, Double)]) -> LatLon? {
    Interpolation.alongPath(fraction: fraction, positions: positions)
}