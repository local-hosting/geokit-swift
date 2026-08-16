import Foundation
import Turf

public enum Interpolation {
    /// Interpolate a point at a fraction along a polyline path.
    public static func alongPath(fraction: Double, coordinates: [LatLon]) -> LatLon? {
        guard !coordinates.isEmpty else { return nil }

        let clamped = max(0, min(1, fraction))
        if coordinates.count == 1 || clamped == 0 {
            return coordinates[0]
        }
        if clamped == 1 {
            return coordinates[coordinates.count - 1]
        }

        if let line = TurfBridge.turfLineString(from: coordinates),
           let totalDistance = line.distance(),
           totalDistance > 0,
           let slice = line.trimmed(from: 0, to: totalDistance * clamped),
           let last = slice.coordinates.last {
            return TurfBridge.latLon(last)
        }

        let pathIndex = clamped * Double(coordinates.count - 1)
        let segmentIndex = min(Int(floor(pathIndex)), coordinates.count - 2)
        let segmentProgress = pathIndex - Double(segmentIndex)
        let start = coordinates[segmentIndex]
        let end = coordinates[segmentIndex + 1]

        return LatLon(
            latitude: start.latitude + (end.latitude - start.latitude) * segmentProgress,
            longitude: start.longitude + (end.longitude - start.longitude) * segmentProgress
        )
    }

    /// Interpolate along a GeoJSON line string (`[lon, lat]` vertices).
    public static func alongPath(fraction: Double, lineString: GeoJSONLineString) -> LatLon? {
        let coordinates = lineString.coordinates.map { position in
            LatLon(latitude: position[1], longitude: position[0])
        }
        return alongPath(fraction: fraction, coordinates: coordinates)
    }

    /// Interpolate along coordinate pairs in either `[lat, lon]` or `[lon, lat]` order.
    public static func alongPath(fraction: Double, positions: [(Double, Double)]) -> LatLon? {
        let coordinates = CoordinateExtraction.normalizeToLatLon(positions)
        guard !coordinates.isEmpty else { return nil }
        return alongPath(fraction: fraction, coordinates: coordinates)
    }
}
