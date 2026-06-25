import Foundation

public typealias GeoJSONPosition = [Double]

public struct GeoJSONPoint: Codable, Equatable, Sendable {
    public var type = "Point"
    public var coordinates: GeoJSONPosition

    public init(coordinates: GeoJSONPosition) {
        self.coordinates = coordinates
    }
}

public struct GeoJSONLineString: Codable, Equatable, Sendable {
    public var type = "LineString"
    public var coordinates: [GeoJSONPosition]

    public init(coordinates: [GeoJSONPosition]) {
        self.coordinates = coordinates
    }
}

public struct GeoJSONPolygon: Codable, Equatable, Sendable {
    public var type = "Polygon"
    public var coordinates: [[GeoJSONPosition]]

    public init(coordinates: [[GeoJSONPosition]]) {
        self.coordinates = coordinates
    }
}

public struct GeoJSONMultiPoint: Codable, Equatable, Sendable {
    public var type = "MultiPoint"
    public var coordinates: [GeoJSONPosition]

    public init(coordinates: [GeoJSONPosition]) {
        self.coordinates = coordinates
    }
}

public struct GeoJSONMultiLineString: Codable, Equatable, Sendable {
    public var type = "MultiLineString"
    public var coordinates: [[GeoJSONPosition]]

    public init(coordinates: [[GeoJSONPosition]]) {
        self.coordinates = coordinates
    }
}

public struct GeoJSONMultiPolygon: Codable, Equatable, Sendable {
    public var type = "MultiPolygon"
    public var coordinates: [[[GeoJSONPosition]]]

    public init(coordinates: [[[GeoJSONPosition]]]) {
        self.coordinates = coordinates
    }
}

public struct GeoJSONGeometryCollection: Codable, Equatable, Sendable {
    public var type = "GeometryCollection"
    public var geometries: [GeoJSONGeometry]

    public init(geometries: [GeoJSONGeometry]) {
        self.geometries = geometries
    }
}

public enum GeoJSONGeometry: Codable, Equatable, Sendable {
    case point(GeoJSONPoint)
    case lineString(GeoJSONLineString)
    case polygon(GeoJSONPolygon)
    case multiPoint(GeoJSONMultiPoint)
    case multiLineString(GeoJSONMultiLineString)
    case multiPolygon(GeoJSONMultiPolygon)
    case geometryCollection(GeoJSONGeometryCollection)

    private enum CodingKeys: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "Point":
            self = .point(try GeoJSONPoint(from: decoder))
        case "LineString":
            self = .lineString(try GeoJSONLineString(from: decoder))
        case "Polygon":
            self = .polygon(try GeoJSONPolygon(from: decoder))
        case "MultiPoint":
            self = .multiPoint(try GeoJSONMultiPoint(from: decoder))
        case "MultiLineString":
            self = .multiLineString(try GeoJSONMultiLineString(from: decoder))
        case "MultiPolygon":
            self = .multiPolygon(try GeoJSONMultiPolygon(from: decoder))
        case "GeometryCollection":
            self = .geometryCollection(try GeoJSONGeometryCollection(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown geometry type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .point(let value): try value.encode(to: encoder)
        case .lineString(let value): try value.encode(to: encoder)
        case .polygon(let value): try value.encode(to: encoder)
        case .multiPoint(let value): try value.encode(to: encoder)
        case .multiLineString(let value): try value.encode(to: encoder)
        case .multiPolygon(let value): try value.encode(to: encoder)
        case .geometryCollection(let value): try value.encode(to: encoder)
        }
    }
}

public struct GeoJSONFeature: Codable, Equatable, Sendable {
    public var type = "Feature"
    public var geometry: GeoJSONGeometry?
    public var properties: [String: GeoJSONValue]

    public init(geometry: GeoJSONGeometry?, properties: [String: GeoJSONValue] = [:]) {
        self.geometry = geometry
        self.properties = properties
    }
}

public struct GeoJSONFeatureCollection: Codable, Equatable, Sendable {
    public var type = "FeatureCollection"
    public var features: [GeoJSONFeature]

    public init(features: [GeoJSONFeature]) {
        self.features = features
    }
}

public enum GeoJSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.typeMismatch(GeoJSONValue.self, .init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        if case .number(let value) = self { return String(value) }
        if case .bool(let value) = self { return value ? "true" : "false" }
        return nil
    }
}
