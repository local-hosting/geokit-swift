import Foundation
import SwiftyH3

/// H3 helpers shaped like Node `@corio-platforms/geokit` `/h3`.
public enum H3 {
    public static func coordinatesToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> String {
        let latLng = H3LatLng(
            latitudeDegs: coordinate.latitude,
            longitudeDegs: coordinate.longitude
        )
        guard let cellResolution = H3Cell.Resolution(rawValue: Int32(resolution)) else {
            throw H3Error.invalidResolution(resolution)
        }
        let cell = try latLng.cell(at: cellResolution)
        return cell.description
    }

    public static func cellToCoordinates(_ cellID: String) throws -> LatLon {
        guard let cell = H3Cell(cellID) else { throw H3Error.invalidCell(cellID) }
        guard cell.isValid else { throw H3Error.invalidCell(cellID) }
        let center = try cell.center
        return LatLon(latitude: center.latitudeDegs, longitude: center.longitudeDegs)
    }

    public static func resolution(of cellID: String) throws -> Int {
        guard let cell = H3Cell(cellID) else { throw H3Error.invalidCell(cellID) }
        guard cell.isValid else { throw H3Error.invalidCell(cellID) }
        return Int(try cell.resolution.rawValue)
    }

    public static func isValid(_ cellID: String) -> Bool {
        guard let cell = H3Cell(cellID) else { return false }
        return cell.isValid
    }

    public static func snapToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> LatLon {
        try cellToCoordinates(coordinatesToCell(coordinate, resolution: resolution))
    }

    public static func cellToBoundary(_ cellID: String) throws -> [LatLon] {
        guard let cell = H3Cell(cellID) else { throw H3Error.invalidCell(cellID) }
        let boundary = try cell.boundary
        return boundary.map { vertex in
            LatLon(latitude: vertex.latitudeDegs, longitude: vertex.longitudeDegs)
        }
    }

    /// Parent cell at a coarser resolution.
    public static func parent(of cellID: String, resolution: Int) throws -> String {
        let cell = try validatedCell(cellID)
        let targetResolution = try resolutionValue(resolution)
        return try cell.parent(at: targetResolution).description
    }

    /// Child cells at a finer resolution.
    public static func children(of cellID: String, resolution: Int) throws -> [String] {
        let cell = try validatedCell(cellID)
        let targetResolution = try resolutionValue(resolution)
        let collection = try cell.children(at: targetResolution)
        return Array(collection).map(\.description)
    }

    /// k-ring disk of neighboring cells (includes the origin cell).
    public static func neighbors(of cellID: String, k: Int = 1) throws -> [String] {
        let cell = try validatedCell(cellID)
        guard k >= 0 else { throw H3Error.invalidRing(k) }
        let disk = try cell.gridDisk(distance: Int32(k))
        return disk.map(\.description)
    }

    public static func areNeighbors(_ cellID1: String, _ cellID2: String) throws -> Bool {
        let cell1 = try validatedCell(cellID1)
        let cell2 = try validatedCell(cellID2)
        return try cell1.isNeighbor(of: cell2)
    }

    /// Average hexagon edge length at a resolution (meters).
    public static func edgeLength(resolution: Int) throws -> Double {
        let cellResolution = try resolutionValue(resolution)
        return cellResolution.averageHexagonEdgeLength.converted(to: .meters).value
    }

    /// Average hexagon area at a resolution (square meters).
    public static func cellArea(resolution: Int) throws -> Double {
        let cellResolution = try resolutionValue(resolution)
        return cellResolution.averageHexagonArea.converted(to: .squareMeters).value
    }

    private static func validatedCell(_ cellID: String) throws -> H3Cell {
        guard let cell = H3Cell(cellID) else { throw H3Error.invalidCell(cellID) }
        guard cell.isValid else { throw H3Error.invalidCell(cellID) }
        return cell
    }

    private static func resolutionValue(_ resolution: Int) throws -> H3Cell.Resolution {
        guard let cellResolution = H3Cell.Resolution(rawValue: Int32(resolution)) else {
            throw H3Error.invalidResolution(resolution)
        }
        return cellResolution
    }
}

public enum H3Error: Error, Equatable {
    case invalidResolution(Int)
    case invalidCell(String)
    case invalidRing(Int)
}
