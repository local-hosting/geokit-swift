import Foundation
import Turf

public enum Centroid {
    public static func polygonCentroid(_ polygon: GeoJSONPolygon) -> LatLon? {
        guard let turfPolygon = TurfBridge.turfPolygon(from: polygon) else { return nil }

        if let centroid = turfPolygon.centroid {
            return TurfBridge.latLon(centroid)
        }

        return boundingBoxCentroid(polygon: polygon)
    }

    public static func pointsCentroid(_ points: [LatLon]) -> LatLon? {
        guard !points.isEmpty else { return nil }
        if points.count == 1 { return points[0] }

        var totalLat = 0.0
        var totalLon = 0.0
        for point in points {
            totalLat += point.latitude
            totalLon += point.longitude
        }

        return LatLon(
            latitude: totalLat / Double(points.count),
            longitude: totalLon / Double(points.count)
        )
    }

    private static func boundingBoxCentroid(polygon: GeoJSONPolygon) -> LatLon? {
        guard let ring = polygon.coordinates.first, ring.count >= 4 else { return nil }

        var minLon = ring[0][0]
        var maxLon = ring[0][0]
        var minLat = ring[0][1]
        var maxLat = ring[0][1]

        for position in ring {
            minLon = min(minLon, position[0])
            maxLon = max(maxLon, position[0])
            minLat = min(minLat, position[1])
            maxLat = max(maxLat, position[1])
        }

        return LatLon(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
    }
}
