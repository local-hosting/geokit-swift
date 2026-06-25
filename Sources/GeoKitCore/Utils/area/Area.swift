import Foundation
import Turf

public enum Area {
    public static func polygonArea(_ polygon: GeoJSONPolygon) -> Double {
        guard let turfPolygon = TurfBridge.turfPolygon(from: polygon) else { return 0 }

        let area = turfPolygon.area
        guard area.isFinite, area >= 0 else { return 0 }
        return area
    }

    public static func polygonAreaKm(_ polygon: GeoJSONPolygon) -> Double {
        polygonArea(polygon) / GeoKitConstants.squareMetersToSquareKilometers
    }

    public static func polygonAreaMiles(_ polygon: GeoJSONPolygon) -> Double {
        polygonArea(polygon) / GeoKitConstants.squareMetersToSquareMiles
    }

    public static func polygonAreaAcres(_ polygon: GeoJSONPolygon) -> Double {
        polygonArea(polygon) / GeoKitConstants.squareMetersToAcres
    }

    public static func boundsArea(_ bounds: Bounds) -> Double {
        guard let bboxPolygon = bboxPolygon(from: bounds) else { return 0 }
        return polygonArea(bboxPolygon)
    }

    public static func boundsAreaKm(_ bounds: Bounds) -> Double {
        boundsArea(bounds) / GeoKitConstants.squareMetersToSquareKilometers
    }

    public static func boundsAreaMiles(_ bounds: Bounds) -> Double {
        boundsArea(bounds) / GeoKitConstants.squareMetersToSquareMiles
    }

    private static func bboxPolygon(from bounds: Bounds) -> GeoJSONPolygon? {
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
