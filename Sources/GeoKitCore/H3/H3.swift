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
}

public enum H3Error: Error, Equatable {
    case invalidResolution(Int)
    case invalidCell(String)
}
