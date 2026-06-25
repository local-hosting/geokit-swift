import Foundation
import Turf

public enum Containment {
    public static func pointInPolygon(_ point: LatLon) -> (GeoJSONPolygon) -> Bool {
        { polygon in isPointInPolygon(point, polygon: polygon) }
    }

    public static func isPointInPolygon(_ point: LatLon, polygon: GeoJSONPolygon) -> Bool {
        guard let turfPolygon = TurfBridge.turfPolygon(from: polygon) else { return false }
        return turfPolygon.contains(TurfBridge.turfCoordinate(point), ignoreBoundary: false)
    }

    public static func boundsContains(_ bounds: Bounds) -> (LatLon) -> Bool {
        { point in isPointInBounds(point, bounds: bounds) }
    }

    public static func isPointInBounds(_ point: LatLon, bounds: Bounds) -> Bool {
        guard let boundingBox = TurfBridge.boundingBox(from: bounds) else { return false }
        return boundingBox.contains(TurfBridge.turfCoordinate(point), ignoreBoundary: false)
    }

    public static func boundsContainsBounds(_ outerBounds: Bounds) -> (Bounds) -> Bool {
        { innerBounds in isBoundsContained(outer: outerBounds, inner: innerBounds) }
    }

    public static func isBoundsContained(outer outerBounds: Bounds, inner innerBounds: Bounds) -> Bool {
        guard outerBounds.count == 4, innerBounds.count == 4 else { return false }

        let outerMinLon = outerBounds[0]
        let outerMinLat = outerBounds[1]
        let outerMaxLon = outerBounds[2]
        let outerMaxLat = outerBounds[3]
        let innerMinLon = innerBounds[0]
        let innerMinLat = innerBounds[1]
        let innerMaxLon = innerBounds[2]
        let innerMaxLat = innerBounds[3]

        return innerMinLon >= outerMinLon
            && innerMaxLon <= outerMaxLon
            && innerMinLat >= outerMinLat
            && innerMaxLat <= outerMaxLat
    }

    public static func boundsIntersects(_ bounds1: Bounds) -> (Bounds) -> Bool {
        { bounds2 in doBoundsIntersect(bounds1, bounds2) }
    }

    public static func doBoundsIntersect(_ bounds1: Bounds, _ bounds2: Bounds) -> Bool {
        guard bounds1.count == 4, bounds2.count == 4 else { return false }

        let minLon1 = bounds1[0]
        let minLat1 = bounds1[1]
        let maxLon1 = bounds1[2]
        let maxLat1 = bounds1[3]
        let minLon2 = bounds2[0]
        let minLat2 = bounds2[1]
        let maxLon2 = bounds2[2]
        let maxLat2 = bounds2[3]

        return !(maxLon1 < minLon2 || minLon1 > maxLon2 || maxLat1 < minLat2 || minLat1 > maxLat2)
    }
}
