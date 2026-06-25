import Foundation

/// Provider-neutral map camera — center, zoom, bearing, and pitch shared across Mapbox and Apple Maps.
public struct MapCameraFrame: Sendable, Equatable {
    public var centerLatitude: Double
    public var centerLongitude: Double
    public var zoom: Double
    public var bearing: Double
    public var pitch: Double

    public init(
        centerLatitude: Double,
        centerLongitude: Double,
        zoom: Double,
        bearing: Double = 0,
        pitch: Double = 50
    ) {
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.zoom = zoom
        self.bearing = bearing
        self.pitch = pitch
    }
}
