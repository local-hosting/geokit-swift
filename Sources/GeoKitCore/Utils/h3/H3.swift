import Ch3
import Foundation

/// H3 helpers shaped like Node `@doppler-group/geokit` `/h3`.
///
/// Backed directly by Uber's H3 C library (vendored as the `Ch3` binary
/// framework) so no C source target is compiled into the build graph.
public enum H3 {
    public static func coordinatesToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> String {
        let res = try resolutionValue(resolution)
        var location = LatLng(lat: degsToRads(coordinate.latitude), lng: degsToRads(coordinate.longitude))
        var cell: H3Index = 0
        try check(latLngToCell(&location, res, &cell))
        return cellString(cell)
    }

    public static func cellToCoordinates(_ cellID: String) throws -> LatLon {
        var center = LatLng(lat: 0, lng: 0)
        try check(cellToLatLng(try validatedCell(cellID), &center))
        return latLon(center)
    }

    public static func resolution(of cellID: String) throws -> Int {
        Int(getResolution(try validatedCell(cellID)))
    }

    public static func isValid(_ cellID: String) -> Bool {
        guard let cell = parsedCell(cellID) else { return false }
        return isValidCell(cell) == 1
    }

    public static func snapToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> LatLon {
        try cellToCoordinates(coordinatesToCell(coordinate, resolution: resolution))
    }

    public static func cellToBoundary(_ cellID: String) throws -> [LatLon] {
        let cell = try validatedCell(cellID)
        var boundary = CellBoundary()
        try check(Ch3.cellToBoundary(cell, &boundary))
        return withUnsafePointer(to: boundary.verts) { tuple in
            tuple.withMemoryRebound(to: LatLng.self, capacity: Int(MAX_CELL_BNDRY_VERTS)) { verts in
                (0 ..< Int(boundary.numVerts)).map { latLon(verts[$0]) }
            }
        }
    }

    /// Parent cell at a coarser resolution.
    public static func parent(of cellID: String, resolution: Int) throws -> String {
        let res = try resolutionValue(resolution)
        var parent: H3Index = 0
        try check(cellToParent(try validatedCell(cellID), res, &parent))
        return cellString(parent)
    }

    /// Child cells at a finer resolution.
    public static func children(of cellID: String, resolution: Int) throws -> [String] {
        let cell = try validatedCell(cellID)
        let res = try resolutionValue(resolution)
        var count: Int64 = 0
        try check(cellToChildrenSize(cell, res, &count))
        var output = [H3Index](repeating: 0, count: Int(max(0, count)))
        try check(cellToChildren(cell, res, &output))
        return output.filter { $0 != 0 }.map(cellString)
    }

    /// k-ring disk of neighboring cells (includes the origin cell).
    public static func neighbors(of cellID: String, k: Int = 1) throws -> [String] {
        guard k >= 0 else { throw H3Error.invalidRing(k) }
        let cell = try validatedCell(cellID)
        var count: Int64 = 0
        try check(maxGridDiskSize(Int32(k), &count))
        var output = [H3Index](repeating: 0, count: Int(max(0, count)))
        try check(gridDisk(cell, Int32(k), &output))
        return output.filter { $0 != 0 }.map(cellString)
    }

    public static func areNeighbors(_ cellID1: String, _ cellID2: String) throws -> Bool {
        var result: Int32 = 0
        try check(areNeighborCells(try validatedCell(cellID1), try validatedCell(cellID2), &result))
        return result == 1
    }

    /// Roll a cell up/down to a target resolution (compact hex id out).
    public static func normalizeToResolution(_ cellID: String, resolution: Int) throws -> String {
        let trimmed = cellID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        var cell = try validatedCell(trimmed)
        var res = Int(getResolution(cell))

        while res > resolution {
            var parent: H3Index = 0
            try check(cellToParent(cell, Int32(res - 1), &parent))
            cell = parent
            res -= 1
        }

        if res < resolution {
            var center = LatLng(lat: 0, lng: 0)
            try check(cellToLatLng(cell, &center))
            let coordinate = latLon(center)
            cell = try validatedCell(try coordinatesToCell(coordinate, resolution: resolution))
        }

        return cellString(cell)
    }

    /// Average hexagon edge length at a resolution (meters).
    public static func edgeLength(resolution: Int) throws -> Double {
        let res = try resolutionValue(resolution)
        var meters: Double = 0
        try check(getHexagonEdgeLengthAvgM(res, &meters))
        return meters
    }

    /// Average hexagon area at a resolution (square meters).
    public static func cellArea(resolution: Int) throws -> Double {
        let res = try resolutionValue(resolution)
        var squareMeters: Double = 0
        try check(getHexagonAreaAvgM2(res, &squareMeters))
        return squareMeters
    }

    private static func parsedCell(_ cellID: String) -> H3Index? {
        var cell: H3Index = 0
        let parsed = cellID.withCString { stringToH3($0, &cell) } == 0
        return (parsed && cell != 0) ? cell : nil
    }

    private static func validatedCell(_ cellID: String) throws -> H3Index {
        guard let cell = parsedCell(cellID), isValidCell(cell) == 1 else {
            throw H3Error.invalidCell(cellID)
        }
        return cell
    }

    private static func cellString(_ cell: H3Index) -> String {
        var buffer = [CChar](repeating: 0, count: 17) // 16 hex digits + NUL
        _ = h3ToString(cell, &buffer, buffer.count)
        return String(cString: buffer)
    }

    private static func latLon(_ coordinate: LatLng) -> LatLon {
        LatLon(latitude: radsToDegs(coordinate.lat), longitude: radsToDegs(coordinate.lng))
    }

    private static func resolutionValue(_ resolution: Int) throws -> Int32 {
        guard (0 ... 15).contains(resolution) else {
            throw H3Error.invalidResolution(resolution)
        }
        return Int32(resolution)
    }

    /// Maps a nonzero H3 `H3Error` status code to ``H3Error/operationFailed(_:)``.
    private static func check(_ status: UInt32) throws {
        guard status == 0 else { throw H3Error.operationFailed(status) }
    }
}

public enum H3Error: Error, Equatable {
    case invalidResolution(Int)
    case invalidCell(String)
    case invalidRing(Int)
    case operationFailed(UInt32)
}
