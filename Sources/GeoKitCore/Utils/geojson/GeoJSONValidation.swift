import Foundation

public struct GeoJSONValidationResult: Equatable, Sendable {
    public var valid: Bool
    public var error: String?

    public init(valid: Bool, error: String? = nil) {
        self.valid = valid
        self.error = error
    }
}

public enum GeoJSONValidation {
    public static func isValidPosition(_ position: GeoJSONPosition) -> Bool {
        guard position.count >= 2, position.count <= 3 else { return false }
        let lon = position[0]
        let lat = position[1]
        guard lon.isFinite, lat.isFinite else { return false }
        guard lat >= GeoKitConstants.minLatitude, lat <= GeoKitConstants.maxLatitude else { return false }
        guard lon >= GeoKitConstants.minLongitude, lon <= GeoKitConstants.maxLongitude else { return false }
        if position.count == 3, !position[2].isFinite { return false }
        return true
    }

    public static func isValidPoint(_ geometry: GeoJSONPoint) -> Bool {
        isValidPosition(geometry.coordinates)
    }

    public static func isValidLineString(_ geometry: GeoJSONLineString) -> Bool {
        geometry.coordinates.count >= 2 && geometry.coordinates.allSatisfy(isValidPosition)
    }

    public static func isValidPolygonRing(_ ring: [GeoJSONPosition]) -> Bool {
        guard ring.count >= 4, ring.allSatisfy(isValidPosition) else { return false }
        let first = ring[0]
        let last = ring[ring.count - 1]
        return first[0] == last[0] && first[1] == last[1]
    }

    public static func isValidPolygon(_ geometry: GeoJSONPolygon) -> Bool {
        !geometry.coordinates.isEmpty && geometry.coordinates.allSatisfy(isValidPolygonRing)
    }

    public static func isValidMultiPoint(_ geometry: GeoJSONMultiPoint) -> Bool {
        !geometry.coordinates.isEmpty && geometry.coordinates.allSatisfy(isValidPosition)
    }

    public static func isValidMultiLineString(_ geometry: GeoJSONMultiLineString) -> Bool {
        !geometry.coordinates.isEmpty && geometry.coordinates.allSatisfy { $0.count >= 2 && $0.allSatisfy(isValidPosition) }
    }

    public static func isValidMultiPolygon(_ geometry: GeoJSONMultiPolygon) -> Bool {
        !geometry.coordinates.isEmpty && geometry.coordinates.allSatisfy { polygon in
            !polygon.isEmpty && polygon.allSatisfy(isValidPolygonRing)
        }
    }

    public static func isValidGeometryCollection(_ geometry: GeoJSONGeometryCollection) -> Bool {
        !geometry.geometries.isEmpty && geometry.geometries.allSatisfy(isValidGeometry)
    }

    public static func isValidGeometry(_ geometry: GeoJSONGeometry) -> Bool {
        switch geometry {
        case .point(let value): return isValidPoint(value)
        case .lineString(let value): return isValidLineString(value)
        case .polygon(let value): return isValidPolygon(value)
        case .multiPoint(let value): return isValidMultiPoint(value)
        case .multiLineString(let value): return isValidMultiLineString(value)
        case .multiPolygon(let value): return isValidMultiPolygon(value)
        case .geometryCollection(let value): return isValidGeometryCollection(value)
        }
    }

    public static func isValidFeature(_ feature: GeoJSONFeature) -> Bool {
        guard let geometry = feature.geometry else { return false }
        return isValidGeometry(geometry)
    }

    public static func isValidFeatureCollection(_ collection: GeoJSONFeatureCollection) -> Bool {
        !collection.features.isEmpty && collection.features.allSatisfy(isValidFeature)
    }

    public static func validate(_ value: GeoJSONFeature) -> GeoJSONValidationResult {
        isValidFeature(value) ? GeoJSONValidationResult(valid: true) : GeoJSONValidationResult(valid: false, error: "Invalid feature")
    }

    public static func validate(_ value: GeoJSONFeatureCollection) -> GeoJSONValidationResult {
        isValidFeatureCollection(value) ? GeoJSONValidationResult(valid: true) : GeoJSONValidationResult(valid: false, error: "Invalid feature collection")
    }

    public static func validate(_ value: GeoJSONGeometry) -> GeoJSONValidationResult {
        isValidGeometry(value) ? GeoJSONValidationResult(valid: true) : GeoJSONValidationResult(valid: false, error: "Invalid geometry")
    }
}
