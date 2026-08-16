#if !os(iOS) && !os(macOS)
import Foundation

/// H3 is backed by the GeoKitCh3 binary framework on iOS and macOS only.
public enum H3 {
    public static func coordinatesToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> String {
        throw H3Error.unavailableOnPlatform
    }

    public static func cellToCoordinates(_ cellID: String) throws -> LatLon {
        throw H3Error.unavailableOnPlatform
    }

    public static func resolution(of cellID: String) throws -> Int {
        throw H3Error.unavailableOnPlatform
    }

    public static func isValid(_ cellID: String) -> Bool { false }

    public static func snapToCell(_ coordinate: LatLon, resolution: Int = 9) throws -> LatLon {
        throw H3Error.unavailableOnPlatform
    }

    public static func cellToBoundary(_ cellID: String) throws -> [LatLon] {
        throw H3Error.unavailableOnPlatform
    }

    public static func parent(of cellID: String, resolution: Int) throws -> String {
        throw H3Error.unavailableOnPlatform
    }

    public static func children(of cellID: String, resolution: Int) throws -> [String] {
        throw H3Error.unavailableOnPlatform
    }

    public static func neighbors(of cellID: String, k: Int = 1) throws -> [String] {
        throw H3Error.unavailableOnPlatform
    }

    public static func areNeighbors(_ cellID1: String, _ cellID2: String) throws -> Bool {
        throw H3Error.unavailableOnPlatform
    }

    public static func edgeLength(resolution: Int) throws -> Double {
        throw H3Error.unavailableOnPlatform
    }

    public static func cellArea(resolution: Int) throws -> Double {
        throw H3Error.unavailableOnPlatform
    }
}

public enum H3Error: Error, Equatable {
    case invalidResolution(Int)
    case invalidCell(String)
    case invalidRing(Int)
    case operationFailed(UInt32)
    case unavailableOnPlatform
}
#endif
