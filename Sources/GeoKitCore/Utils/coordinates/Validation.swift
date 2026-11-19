import Foundation

/// Mirrors `geokit/src/core/src/utils/coordinates/validation.ts`.

public func isValidCoordinate(_ coordinate: LatLon) -> Bool {
    Coordinates.isValid(coordinate)
}