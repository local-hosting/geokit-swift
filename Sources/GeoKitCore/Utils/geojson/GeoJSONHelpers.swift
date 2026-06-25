import Foundation

public enum GeoJSONHelpers {
    public static func getCoordinates(from feature: GeoJSONFeature) -> GeoJSONPosition? {
        guard let geometry = feature.geometry else { return nil }
        return getCoordinates(from: geometry)
    }

    public static func getCoordinates(from geometry: GeoJSONGeometry) -> GeoJSONPosition? {
        if case .point(let point) = geometry {
            return point.coordinates
        }
        return nil
    }

    public static func createFeature(
        geometry: GeoJSONGeometry,
        properties: [String: GeoJSONValue] = [:]
    ) -> GeoJSONFeature {
        GeoJSONFeature(geometry: geometry, properties: properties)
    }

    public static func createFeatureCollection(_ features: [GeoJSONFeature]) -> GeoJSONFeatureCollection {
        GeoJSONFeatureCollection(features: features)
    }

    public static func extractGeometry(from feature: GeoJSONFeature) -> GeoJSONGeometry? {
        feature.geometry
    }

    public static func getFeatureId(
        from feature: GeoJSONFeature,
        idProperties: [String] = ["id", "slug"]
    ) -> String? {
        for key in idProperties {
            if let value = feature.properties[key]?.stringValue {
                return value
            }
        }
        return nil
    }

    public static func formatJSONCompact(_ value: some Encodable, minify: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        if minify {
            encoder.outputFormatting = [.sortedKeys]
        } else {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(value)
        guard var text = String(data: data, encoding: .utf8) else { return "" }
        if !minify {
            text = text.replacingOccurrences(
                of: #"\[\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*\]"#,
                with: "[$1,$2]",
                options: .regularExpression
            )
        }
        return text
    }
}
