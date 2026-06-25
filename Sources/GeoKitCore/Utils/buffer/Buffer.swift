import Foundation
import Turf

public enum BufferError: Error, Equatable {
    case failedToCreateBuffer
    case lineRequiresAtLeastTwoCoordinates
    case unsupportedGeometry(String)
}

public enum Buffer {
    /// Circular buffer around a point via Turf circle (`Polygon(center:radius:vertices:)`).
    public static func bufferPoint(
        _ point: LatLon,
        radiusMeters: Double,
        steps: Int = GeoKitConstants.defaultBufferSteps
    ) throws -> GeoJSONPolygon {
        guard radiusMeters >= 0, steps >= 3 else {
            throw BufferError.failedToCreateBuffer
        }

        let center = TurfBridge.turfCoordinate(point)
        let polygon = Turf.Polygon(center: center, radius: radiusMeters, vertices: steps)
        return TurfBridge.geoJSONPolygon(from: polygon)
    }

    /// Line and polygon buffering is not available in Turf Swift (no turf-buffer port).
    public static func bufferLine(
        _ coordinates: [LatLon],
        radiusMeters: Double,
        steps: Int = GeoKitConstants.defaultBufferSteps
    ) throws -> GeoJSONPolygon {
        guard coordinates.count >= 2 else {
            throw BufferError.lineRequiresAtLeastTwoCoordinates
        }
        throw BufferError.unsupportedGeometry("Turf Swift does not include turf-buffer for lines")
    }

    public static func bufferPolygon(
        _ polygon: GeoJSONPolygon,
        radiusMeters: Double,
        steps: Int = GeoKitConstants.defaultBufferSteps
    ) throws -> GeoJSONPolygon {
        guard TurfBridge.turfPolygon(from: polygon) != nil else {
            throw BufferError.failedToCreateBuffer
        }
        throw BufferError.unsupportedGeometry("Turf Swift does not include turf-buffer for polygons")
    }
}
