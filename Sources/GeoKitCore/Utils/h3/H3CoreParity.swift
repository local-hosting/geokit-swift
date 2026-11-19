import Foundation

#if os(iOS) || os(macOS)

/// Node `@local-hosting/geokit/h3` names — mirrors `geometry/core.ts`.

public func coordinatesToH3(_ coordinate: LatLon, resolution: Int = 9) throws -> String {
    try H3.coordinatesToCell(coordinate, resolution: resolution)
}

public func h3ToCoordinates(_ h3Index: String) throws -> LatLon {
    try H3.cellToCoordinates(h3Index)
}

public func h3GetResolution(_ h3Index: String) throws -> Int {
    try H3.resolution(of: h3Index)
}

public func validateH3(_ h3Index: String) -> Bool {
    H3.isValid(h3Index)
}

public func snapToH3Cell(_ coordinate: LatLon, resolution: Int = 9) throws -> LatLon {
    try H3.snapToCell(coordinate, resolution: resolution)
}

#endif