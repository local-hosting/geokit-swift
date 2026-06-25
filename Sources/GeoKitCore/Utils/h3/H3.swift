import Ch3
import Foundation

/// H3 helpers shaped like Node `@corio-platforms/geokit` `/h3`.
public enum H3 {
    public static func coordinatesToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> String {
        let cell = try latLngToCellIndex(coordinate, resolution: resolution)
        return try indexToString(cell)
    }

    public static func cellToCoordinates(_ cellID: String) throws -> LatLon {
        let index = try stringToIndex(cellID)
        try validateCell(index, cellID: cellID)
        return try indexToLatLon(index)
    }

    public static func resolution(of cellID: String) throws -> Int {
        let index = try stringToIndex(cellID)
        try validateCell(index, cellID: cellID)
        return Int(getResolution(index))
    }

    public static func isValid(_ cellID: String) -> Bool {
        guard let index = try? stringToIndex(cellID) else { return false }
        return isValidCell(index) != 0
    }

    public static func snapToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> LatLon {
        try cellToCoordinates(coordinatesToCell(coordinate, resolution: resolution))
    }

    public static func cellToBoundary(_ cellID: String) throws -> [LatLon] {
        let index = try stringToIndex(cellID)
        try validateCell(index, cellID: cellID)

        var boundary = CellBoundary()
        try throwIfNeeded(Ch3.cellToBoundary(index, &boundary))

        return withUnsafePointer(to: boundary.verts) { vertsPointer in
            vertsPointer.withMemoryRebound(to: LatLng.self, capacity: Int(boundary.numVerts)) { latLngPointer in
                (0 ..< Int(boundary.numVerts)).map { vertexIndex in
                    let vertex = latLngPointer[vertexIndex]
                    return LatLon(
                        latitude: radsToDegs(vertex.lat),
                        longitude: radsToDegs(vertex.lng)
                    )
                }
            }
        }
    }

    /// Parent cell at a coarser resolution.
    public static func parent(of cellID: String, resolution: Int) throws -> String {
        let index = try validatedIndex(cellID)
        let targetResolution = try resolutionValue(resolution)

        var parent: H3Index = 0
        try throwIfNeeded(cellToParent(index, targetResolution, &parent))
        return try indexToString(parent)
    }

    /// Child cells at a finer resolution.
    public static func children(of cellID: String, resolution: Int) throws -> [String] {
        let index = try validatedIndex(cellID)
        let targetResolution = try resolutionValue(resolution)

        var childCount: Int64 = 0
        try throwIfNeeded(cellToChildrenSize(index, targetResolution, &childCount))

        var children = [H3Index](repeating: 0, count: Int(childCount))
        try throwIfNeeded(cellToChildren(index, targetResolution, &children))
        return try children.map { try indexToString($0) }
    }

    /// k-ring disk of neighboring cells (includes the origin cell).
    public static func neighbors(of cellID: String, k: Int = 1) throws -> [String] {
        let index = try validatedIndex(cellID)
        guard k >= 0 else { throw H3Error.invalidRing(k) }

        var diskSize: Int64 = 0
        try throwIfNeeded(maxGridDiskSize(Int32(k), &diskSize))

        var disk = [H3Index](repeating: 0, count: Int(diskSize))
        try throwIfNeeded(gridDisk(index, Int32(k), &disk))
        return try disk.map { try indexToString($0) }
    }

    public static func areNeighbors(_ cellID1: String, _ cellID2: String) throws -> Bool {
        let index1 = try validatedIndex(cellID1)
        let index2 = try validatedIndex(cellID2)

        var neighbors: Int32 = 0
        try throwIfNeeded(areNeighborCells(index1, index2, &neighbors))
        return neighbors != 0
    }

    /// Average hexagon edge length at a resolution (meters).
    public static func edgeLength(resolution: Int) throws -> Double {
        let targetResolution = try resolutionValue(resolution)
        var lengthMeters = 0.0
        try throwIfNeeded(getHexagonEdgeLengthAvgM(targetResolution, &lengthMeters))
        return lengthMeters
    }

    /// Average hexagon area at a resolution (square meters).
    public static func cellArea(resolution: Int) throws -> Double {
        let targetResolution = try resolutionValue(resolution)
        var areaSquareMeters = 0.0
        try throwIfNeeded(getHexagonAreaAvgM2(targetResolution, &areaSquareMeters))
        return areaSquareMeters
    }

    private static func validatedIndex(_ cellID: String) throws -> H3Index {
        let index = try stringToIndex(cellID)
        try validateCell(index, cellID: cellID)
        return index
    }

    private static func latLngToCellIndex(_ coordinate: LatLon, resolution: Int) throws -> H3Index {
        let targetResolution = try resolutionValue(resolution)
        var latLng = LatLng(
            lat: degsToRads(coordinate.latitude),
            lng: degsToRads(coordinate.longitude)
        )
        var cell: H3Index = 0
        try throwIfNeeded(latLngToCell(&latLng, targetResolution, &cell))
        return cell
    }

    private static func indexToLatLon(_ index: H3Index) throws -> LatLon {
        var latLng = LatLng(lat: 0, lng: 0)
        try throwIfNeeded(cellToLatLng(index, &latLng))
        return LatLon(
            latitude: radsToDegs(latLng.lat),
            longitude: radsToDegs(latLng.lng)
        )
    }

    private static func indexToString(_ index: H3Index) throws -> String {
        var buffer = [CChar](repeating: 0, count: 17)
        try throwIfNeeded(h3ToString(index, &buffer, buffer.count))
        return String(cString: buffer)
    }

    private static func stringToIndex(_ cellID: String) throws -> H3Index {
        var index: H3Index = 0
        try throwIfNeeded(stringToH3(cellID, &index))
        return index
    }

    private static func validateCell(_ index: H3Index, cellID: String) throws {
        guard isValidCell(index) != 0 else {
            throw H3Error.invalidCell(cellID)
        }
    }

    private static func resolutionValue(_ resolution: Int) throws -> Int32 {
        guard (0 ... 15).contains(resolution) else {
            throw H3Error.invalidResolution(resolution)
        }
        return Int32(resolution)
    }

    private static func throwIfNeeded(_ code: UInt32) throws {
        guard code == UInt32(E_SUCCESS.rawValue) else {
            throw H3Error.operationFailed(code)
        }
    }
}

public enum H3Error: Error, Equatable {
    case invalidResolution(Int)
    case invalidCell(String)
    case invalidRing(Int)
    case operationFailed(UInt32)
}
