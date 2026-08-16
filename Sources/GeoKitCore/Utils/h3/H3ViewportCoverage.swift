import Foundation

public struct ViewportBounds: Equatable, Sendable {
    public var west: Double
    public var south: Double
    public var east: Double
    public var north: Double

    public init(west: Double, south: Double, east: Double, north: Double) {
        self.west = west
        self.south = south
        self.east = east
        self.north = north
    }
}

public enum H3ViewportCoverage {
    public static let defaultMaxViewportEval = 1500

    /// Center-priority disk tessellation fallback (matches geokit when polygon fill is empty).
    public static func cellsForViewport(
        _ bounds: ViewportBounds,
        resolution: Int,
        fallbackDiskK: Int = 2,
        maxEvalCells: Int = defaultMaxViewportEval
    ) throws -> [String] {
        let lat = (bounds.south + bounds.north) / 2
        let lng = (bounds.west + bounds.east) / 2
        let center = try H3.coordinatesToCell(LatLon(latitude: lat, longitude: lng), resolution: resolution)
        let disk = try H3.neighbors(of: center, k: fallbackDiskK)
        if disk.count > maxEvalCells { return [] }
        return disk
    }

    public static func filterCellsInCoverage(
        _ cells: [String],
        coverageIndex: Set<String>,
        resolution: Int
    ) throws -> [String] {
        let normalizedIndex = try Set(coverageIndex.map { try H3.normalizeToResolution($0, resolution: resolution) })
        return try cells.filter { cell in
            let normalized = try H3.normalizeToResolution(cell.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), resolution: resolution)
            return normalizedIndex.contains(normalized)
        }
    }

    public static func viewportCoverageCells(
        bounds: ViewportBounds,
        coverageIndex: Set<String>,
        resolution: Int,
        maxEvalCells: Int = defaultMaxViewportEval
    ) throws -> [String] {
        let cells = try cellsForViewport(bounds, resolution: resolution, maxEvalCells: maxEvalCells)
        return try filterCellsInCoverage(cells, coverageIndex: coverageIndex, resolution: resolution)
    }
}
