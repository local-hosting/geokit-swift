import Foundation
import SwiftyH3

/// H3 helpers shaped like Node `@corio-platforms/geokit` `/h3`.
public enum H3 {
    public static func coordinatesToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> String {
        let cell = try latLng(coordinate).cell(at: resolutionValue(resolution))
        return cell.description
    }

    public static func cellToCoordinates(_ cellID: String) throws -> LatLon {
        let center = try validatedCell(cellID).center
        return latLon(center)
    }

    public static func resolution(of cellID: String) throws -> Int {
        Int(try validatedCell(cellID).resolution.rawValue)
    }

    public static func isValid(_ cellID: String) -> Bool {
        H3Cell(cellID)?.isValid ?? false
    }

    public static func snapToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> LatLon {
        try cellToCoordinates(coordinatesToCell(coordinate, resolution: resolution))
    }

    public static func cellToBoundary(_ cellID: String) throws -> [LatLon] {
        try validatedCell(cellID).boundary.map(latLon)
    }

    /// Parent cell at a coarser resolution.
    public static func parent(of cellID: String, resolution: Int) throws -> String {
        let parent = try validatedCell(cellID).parent(at: resolutionValue(resolution))
        return parent.description
    }

    /// Child cells at a finer resolution.
    public static func children(of cellID: String, resolution: Int) throws -> [String] {
        let children = try validatedCell(cellID).children(at: resolutionValue(resolution))
        return children.map { $0.description }
    }

    /// k-ring disk of neighboring cells (includes the origin cell).
    public static func neighbors(of cellID: String, k: Int = 1) throws -> [String] {
        guard k >= 0 else { throw H3Error.invalidRing(k) }
        let disk = try validatedCell(cellID).gridDisk(distance: Int32(k))
        return disk.map { $0.description }
    }

    public static func areNeighbors(_ cellID1: String, _ cellID2: String) throws -> Bool {
        try validatedCell(cellID1).isNeighbor(of: validatedCell(cellID2))
    }

    /// Average hexagon edge length at a resolution (meters).
    public static func edgeLength(resolution: Int) throws -> Double {
        try resolutionValue(resolution).averageHexagonEdgeLength.value
    }

    /// Average hexagon area at a resolution (square meters).
    public static func cellArea(resolution: Int) throws -> Double {
        try resolutionValue(resolution).averageHexagonArea.value
    }

    private static func validatedCell(_ cellID: String) throws -> H3Cell {
        guard let cell = H3Cell(cellID), cell.isValid else {
            throw H3Error.invalidCell(cellID)
        }
        return cell
    }

    private static func latLng(_ coordinate: LatLon) -> H3LatLng {
        H3LatLng(latitudeDegs: coordinate.latitude, longitudeDegs: coordinate.longitude)
    }

    private static func latLon(_ coordinate: H3LatLng) -> LatLon {
        LatLon(latitude: coordinate.latitudeDegs, longitude: coordinate.longitudeDegs)
    }

    private static func resolutionValue(_ resolution: Int) throws -> H3Cell.Resolution {
        guard
            (0 ... 15).contains(resolution),
            let value = H3Cell.Resolution(rawValue: Int32(resolution))
        else {
            throw H3Error.invalidResolution(resolution)
        }
        return value
    }
}

public enum H3Error: Error, Equatable {
    case invalidResolution(Int)
    case invalidCell(String)
    case invalidRing(Int)
    case operationFailed(UInt32)
}
