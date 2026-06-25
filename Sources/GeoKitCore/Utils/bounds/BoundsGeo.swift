import Foundation
import Turf

public enum BoundsGeo {
    public static func getBounds(from coordinates: [LatLon]) -> Bounds? {
        guard let boundingBox = TurfBridge.turfBoundingBox(from: coordinates) else { return nil }
        return TurfBridge.bounds(from: boundingBox)
    }

    public static func getBounds(from coordinatePairs: [(Double, Double)]) -> Bounds? {
        let coordinates = CoordinateExtraction.normalizeToLatLon(coordinatePairs)
        return getBounds(from: coordinates)
    }

    public static func getBounds(from geometry: GeoJSONGeometry) -> Bounds? {
        let turfCoordinates = TurfBridge.allCoordinates(from: geometry)
        guard !turfCoordinates.isEmpty,
              let boundingBox = Turf.BoundingBox(from: turfCoordinates) else {
            return nil
        }
        return TurfBridge.bounds(from: boundingBox)
    }

    public static func bboxToPolygon(_ bounds: Bounds) -> [LatLon] {
        guard let polygon = bboxToPolygonGeometry(bounds) else { return [] }
        guard let ring = polygon.coordinates.first else { return [] }

        return ring.map { position in
            LatLon(latitude: position[1], longitude: position[0])
        }
    }

    public static func bboxToPolygonGeometry(_ bounds: Bounds) -> GeoJSONPolygon? {
        guard let boundingBox = TurfBridge.boundingBox(from: bounds) else { return nil }

        let southWest = boundingBox.southWest
        let northEast = boundingBox.northEast
        let ring: [GeoJSONPosition] = [
            [southWest.longitude, southWest.latitude],
            [northEast.longitude, southWest.latitude],
            [northEast.longitude, northEast.latitude],
            [southWest.longitude, northEast.latitude],
            [southWest.longitude, southWest.latitude],
        ]

        let polygon = GeoJSONPolygon(coordinates: [ring])
        return GeoJSONValidation.isValidPolygon(polygon) ? polygon : nil
    }
}
