import Foundation

/// Geographic coordinate as latitude/longitude in degrees.
public struct LatLon: Equatable, Sendable, Codable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public init(_ pair: (Double, Double)) {
        self.latitude = pair.0
        self.longitude = pair.1
    }

    public var tuple: (Double, Double) {
        (latitude, longitude)
    }
}

/// Axis-aligned bounding box: `[minLon, minLat, maxLon, maxLat]`.
public typealias Bounds = [Double]

public struct MapSize: Equatable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct CenterAndZoom: Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double
    public var zoom: Double

    public init(latitude: Double, longitude: Double, zoom: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.zoom = zoom
    }
}

public struct ViewportFit: Equatable, Sendable {
    public var center: LatLon
    public var zoom: Double

    public init(center: LatLon, zoom: Double) {
        self.center = center
        self.zoom = zoom
    }
}
