import Foundation

public enum Distance {
    /// Haversine distance in meters between two coordinates.
    public static func haversineMeters(from: LatLon, to: LatLon) -> Double {
        haversine(from: from, to: to, radius: GeoKitConstants.earthRadiusMeters)
    }

    /// Haversine distance in kilometers between two coordinates.
    public static func haversineKm(from: LatLon, to: LatLon) -> Double {
        haversine(from: from, to: to, radius: GeoKitConstants.earthRadiusKm)
    }

    /// Haversine distance in miles between two coordinates.
    public static func haversineMiles(from: LatLon, to: LatLon) -> Double {
        haversine(from: from, to: to, radius: GeoKitConstants.earthRadiusMiles)
    }

    public static func haversine(from: LatLon, to: LatLon, radius: Double) -> Double {
        if from == to { return 0 }

        let lat1 = from.latitude * GeoKitConstants.degreesToRadians
        let lat2 = to.latitude * GeoKitConstants.degreesToRadians
        let dLat = (to.latitude - from.latitude) * GeoKitConstants.degreesToRadians
        let dLon = (to.longitude - from.longitude) * GeoKitConstants.degreesToRadians

        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return radius * c
    }

    public static func withinDistance(
        _ thresholdMeters: Double,
        from: LatLon,
        to: LatLon
    ) -> Bool {
        haversineMeters(from: from, to: to) <= thresholdMeters
    }
}
