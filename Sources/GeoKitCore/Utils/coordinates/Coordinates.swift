import Foundation

public enum Coordinates {
    /// Convert GeoJSON `[lon, lat]` to `[lat, lon]`.
    public static func toLatLon(longitude: Double, latitude: Double) -> LatLon {
        LatLon(latitude: latitude, longitude: longitude)
    }

    /// Convert GeoJSON `[lon, lat]` pairs to `[lat, lon]`.
    public static func toLatLonArray(_ points: [(longitude: Double, latitude: Double)]) -> [LatLon] {
        points.map { LatLon(latitude: $0.latitude, longitude: $0.longitude) }
    }

    /// Convert `[lat, lon]` to GeoJSON `[lon, lat]`.
    public static func toLonLat(_ coordinate: LatLon) -> (longitude: Double, latitude: Double) {
        (coordinate.longitude, coordinate.latitude)
    }

    /// Convert `[lat, lon]` pairs to GeoJSON `[lon, lat]`.
    public static func toLonLatArray(_ points: [LatLon]) -> [(longitude: Double, latitude: Double)] {
        points.map { (longitude: $0.longitude, latitude: $0.latitude) }
    }

    /// Validate that coordinates are finite numbers within valid geographic ranges.
    public static func isValid(_ coordinate: LatLon) -> Bool {
        let lat = coordinate.latitude
        let lon = coordinate.longitude

        guard lat.isFinite, lon.isFinite else { return false }
        guard lat >= GeoKitConstants.minLatitude, lat <= GeoKitConstants.maxLatitude else { return false }
        guard lon >= GeoKitConstants.minLongitude, lon <= GeoKitConstants.maxLongitude else { return false }
        return true
    }

    /// Normalize longitude to `[-180, 180]`.
    public static func normalizeLongitude(_ longitude: Double) -> Double {
        var lon = longitude
        while lon > GeoKitConstants.maxLongitude { lon -= GeoKitConstants.degreesInCircle }
        while lon < GeoKitConstants.minLongitude { lon += GeoKitConstants.degreesInCircle }
        return lon
    }
}
