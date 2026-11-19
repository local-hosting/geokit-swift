import Foundation

#if os(iOS) || os(macOS)

/// Mirrors `geokit/src/h3/src/geometry/metrics.ts`.

public func h3EdgeLength(resolution: Int) throws -> Double {
    try H3.edgeLength(resolution: resolution)
}

public func h3CellArea(resolution: Int) throws -> Double {
    try H3.cellArea(resolution: resolution)
}

#endif