import Foundation

/// Provider-neutral map camera — center, zoom, bearing, and pitch shared across Mapbox and Apple Maps.
public struct MapCameraFrame: Sendable, Equatable, Codable {
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

    /// Shared tolerances for Mapbox ↔ MapKit round-trip and gesture noise.
    public static let approximateMatch = ApproximateMatch(
        centerDegrees: 0.00001,
        zoom: 0.05,
        bearing: 0.5,
        pitch: 0.5
    )

    public struct ApproximateMatch: Sendable, Equatable {
        public var centerDegrees: Double
        public var zoom: Double
        public var bearing: Double
        public var pitch: Double

        public init(centerDegrees: Double, zoom: Double, bearing: Double, pitch: Double) {
            self.centerDegrees = centerDegrees
            self.zoom = zoom
            self.bearing = bearing
            self.pitch = pitch
        }
    }

    public func isApproximatelyEqual(
        to other: MapCameraFrame,
        tolerance: ApproximateMatch = approximateMatch
    ) -> Bool {
        abs(centerLatitude - other.centerLatitude) <= tolerance.centerDegrees
            && abs(centerLongitude - other.centerLongitude) <= tolerance.centerDegrees
            && abs(zoom - other.zoom) <= tolerance.zoom
            && abs(bearing - other.bearing) <= tolerance.bearing
            && abs(pitch - other.pitch) <= tolerance.pitch
    }
}
