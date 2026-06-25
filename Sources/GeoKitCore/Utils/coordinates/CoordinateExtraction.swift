import Foundation

public enum CoordinateExtraction {
    public static func detectAndConvertCoordinateFormat(_ coord: (Double, Double)) -> LatLon {
        let first = coord.0
        let second = coord.1

        if abs(first) > 90 {
            return LatLon(latitude: second, longitude: first)
        }

        if abs(second) > 90 {
            return LatLon(latitude: first, longitude: second)
        }

        if abs(first) == 90 {
            return LatLon(latitude: first, longitude: second)
        }

        if abs(first) > abs(second), abs(first) < 90 {
            return LatLon(latitude: second, longitude: first)
        }

        return LatLon(latitude: first, longitude: second)
    }

    public static func extractCoordinates(from input: LatLon?) -> LatLon? {
        input
    }

    public static func extractCoordinates(from input: (Double, Double)) -> LatLon? {
        detectAndConvertCoordinateFormat(input)
    }

    public static func extractCoordinates(from input: GeoJSONPoint) -> LatLon? {
        let coordinates = input.coordinates
        guard coordinates.count >= 2 else { return nil }
        return Coordinates.toLatLon(longitude: coordinates[0], latitude: coordinates[1])
    }

    public static func extractCoordinates(latitude: Double, longitude: Double) -> LatLon {
        LatLon(latitude: latitude, longitude: longitude)
    }

    public static func extractCoordinates(lat: Double, lon: Double) -> LatLon {
        LatLon(latitude: lat, longitude: lon)
    }

    public static func normalizeToLatLon(_ coordinates: [(Double, Double)]) -> [LatLon] {
        coordinates.compactMap { pair in
            extractCoordinates(from: pair)
        }
    }
}
