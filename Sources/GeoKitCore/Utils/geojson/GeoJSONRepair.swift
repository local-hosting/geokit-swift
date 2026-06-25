import Foundation

public struct GeoJSONRepairOptions: Sendable, Equatable {
    public var closeRings: Bool
    public var removeDuplicates: Bool
    public var removeInvalidPositions: Bool
    public var coordinatePrecision: Int?
    public var removeEmptyGeometries: Bool

    public init(
        closeRings: Bool = true,
        removeDuplicates: Bool = true,
        removeInvalidPositions: Bool = true,
        coordinatePrecision: Int? = nil,
        removeEmptyGeometries: Bool = true
    ) {
        self.closeRings = closeRings
        self.removeDuplicates = removeDuplicates
        self.removeInvalidPositions = removeInvalidPositions
        self.coordinatePrecision = coordinatePrecision
        self.removeEmptyGeometries = removeEmptyGeometries
    }
}

public enum GeoJSONRepair {
    public static func repairGeometry(_ geometry: GeoJSONGeometry, options: GeoJSONRepairOptions = GeoJSONRepairOptions()) -> GeoJSONGeometry? {
        switch geometry {
        case .point(let point):
            guard let coordinates = repairPosition(point.coordinates, options: options) else { return nil }
            return .point(GeoJSONPoint(coordinates: coordinates))
        case .lineString(let line):
            let coordinates = repairLine(line.coordinates, options: options)
            guard coordinates.count >= 2 else { return options.removeEmptyGeometries ? nil : .lineString(GeoJSONLineString(coordinates: coordinates)) }
            return .lineString(GeoJSONLineString(coordinates: coordinates))
        case .polygon(let polygon):
            let coordinates = repairPolygon(polygon.coordinates, options: options)
            guard !coordinates.isEmpty else { return options.removeEmptyGeometries ? nil : .polygon(GeoJSONPolygon(coordinates: coordinates)) }
            return .polygon(GeoJSONPolygon(coordinates: coordinates))
        case .multiPoint(let multi):
            let coordinates = multi.coordinates.compactMap { repairPosition($0, options: options) }
            guard !coordinates.isEmpty else { return options.removeEmptyGeometries ? nil : .multiPoint(GeoJSONMultiPoint(coordinates: coordinates)) }
            return .multiPoint(GeoJSONMultiPoint(coordinates: coordinates))
        case .multiLineString(let multi):
            let coordinates = multi.coordinates.compactMap { line -> [GeoJSONPosition]? in
                let repaired = repairLine(line, options: options)
                return repaired.count >= 2 ? repaired : nil
            }
            guard !coordinates.isEmpty else { return options.removeEmptyGeometries ? nil : .multiLineString(GeoJSONMultiLineString(coordinates: coordinates)) }
            return .multiLineString(GeoJSONMultiLineString(coordinates: coordinates))
        case .multiPolygon(let multi):
            let coordinates = multi.coordinates.compactMap { polygon -> [[GeoJSONPosition]]? in
                let repaired = repairPolygon(polygon, options: options)
                return repaired.isEmpty ? nil : repaired
            }
            guard !coordinates.isEmpty else { return options.removeEmptyGeometries ? nil : .multiPolygon(GeoJSONMultiPolygon(coordinates: coordinates)) }
            return .multiPolygon(GeoJSONMultiPolygon(coordinates: coordinates))
        case .geometryCollection(let collection):
            let geometries = collection.geometries.compactMap { repairGeometry($0, options: options) }
            guard !geometries.isEmpty else { return options.removeEmptyGeometries ? nil : .geometryCollection(GeoJSONGeometryCollection(geometries: geometries)) }
            return .geometryCollection(GeoJSONGeometryCollection(geometries: geometries))
        }
    }

    public static func repairFeature(_ feature: GeoJSONFeature, options: GeoJSONRepairOptions = GeoJSONRepairOptions()) -> GeoJSONFeature? {
        guard let geometry = feature.geometry else { return nil }
        guard let repaired = repairGeometry(geometry, options: options) else { return nil }
        return GeoJSONFeature(geometry: repaired, properties: feature.properties)
    }

    public static func fixPolygonRingOrder(_ ring: [GeoJSONPosition]) -> [GeoJSONPosition] {
        guard ring.count >= 4 else { return ring }
        let area = signedArea(ring)
        var fixed = ring
        if area > 0 {
            fixed.reverse()
            if fixed.first != fixed.last, let first = fixed.first {
                fixed.append(first)
            }
        }
        return fixed
    }

    private static func repairPosition(_ position: GeoJSONPosition, options: GeoJSONRepairOptions) -> GeoJSONPosition? {
        guard position.count >= 2 else { return nil }
        var lon = position[0]
        var lat = position[1]
        if options.removeInvalidPositions {
            guard GeoJSONValidation.isValidPosition(position) else { return nil }
        }
        if let precision = options.coordinatePrecision {
            let factor = pow(10.0, Double(precision))
            lon = (lon * factor).rounded() / factor
            lat = (lat * factor).rounded() / factor
        }
        if position.count == 3 {
            return [lon, lat, position[2]]
        }
        return [lon, lat]
    }

    private static func repairLine(_ coordinates: [GeoJSONPosition], options: GeoJSONRepairOptions) -> [GeoJSONPosition] {
        let repaired = coordinates.compactMap { repairPosition($0, options: options) }
        return removeDuplicates(repaired, options: options)
    }

    private static func repairPolygon(_ rings: [[GeoJSONPosition]], options: GeoJSONRepairOptions) -> [[GeoJSONPosition]] {
        rings.compactMap { ring in
            var repaired = repairLine(ring, options: options)
            guard repaired.count >= 3 else { return nil }
            if options.closeRings {
                if repaired.first?[0] != repaired.last?[0] || repaired.first?[1] != repaired.last?[1] {
                    if let first = repaired.first {
                        repaired.append(first)
                    }
                }
            }
            return repaired.count >= 4 ? repaired : nil
        }
    }

    private static func removeDuplicates(_ coordinates: [GeoJSONPosition], options: GeoJSONRepairOptions) -> [GeoJSONPosition] {
        guard options.removeDuplicates, coordinates.count > 1 else { return coordinates }
        var result: [GeoJSONPosition] = [coordinates[0]]
        for coordinate in coordinates.dropFirst() {
            let previous = result[result.count - 1]
            if previous[0] != coordinate[0] || previous[1] != coordinate[1] {
                result.append(coordinate)
            }
        }
        return result
    }

    private static func signedArea(_ ring: [GeoJSONPosition]) -> Double {
        guard ring.count >= 3 else { return 0 }
        var area = 0.0
        for index in 0..<(ring.count - 1) {
            let current = ring[index]
            let next = ring[index + 1]
            area += (current[0] * next[1]) - (next[0] * current[1])
        }
        return area / 2
    }
}
