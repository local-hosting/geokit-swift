import Foundation

public enum Bearing {
    /// Same as Node `bearing(from)(to)`.
    public static func bearing(from: LatLon, to: LatLon) -> Double {
        initial(from: from, to: to)
    }

    /// Initial bearing (forward azimuth) in degrees from north, range `[0, 360)`.
    public static func initial(from: LatLon, to: LatLon) -> Double {
        if from == to { return 0 }

        let lat1 = from.latitude * GeoKitConstants.degreesToRadians
        let lat2 = to.latitude * GeoKitConstants.degreesToRadians
        let dLon = (to.longitude - from.longitude) * GeoKitConstants.degreesToRadians

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearingRad = atan2(y, x)
        let bearingDeg = bearingRad * GeoKitConstants.radiansToDegrees
        return normalizeDegrees(bearingDeg)
    }

    /// Same as Node `finalBearing(from)(to)`.
    public static func finalBearing(from: LatLon, to: LatLon) -> Double {
        final(from: from, to: to)
    }

    /// Final bearing at the destination point.
    public static func final(from: LatLon, to: LatLon) -> Double {
        normalizeDegrees(initial(from: to, to: from) + 180)
    }

    /// Great-circle midpoint between two coordinates.
    public static func midpoint(from point1: LatLon, to point2: LatLon) -> LatLon {
        if point1 == point2 { return point1 }

        let lat1 = point1.latitude * GeoKitConstants.degreesToRadians
        let lon1 = point1.longitude * GeoKitConstants.degreesToRadians
        let lat2 = point2.latitude * GeoKitConstants.degreesToRadians
        let deltaLon = (point2.longitude - point1.longitude) * GeoKitConstants.degreesToRadians

        let bx = cos(lat2) * cos(deltaLon)
        let by = cos(lat2) * sin(deltaLon)

        let lat3 = atan2(
            sin(lat1) + sin(lat2),
            sqrt((cos(lat1) + bx) * (cos(lat1) + bx) + by * by)
        )
        let lon3 = lon1 + atan2(by, cos(lat1) + bx)

        return LatLon(
            latitude: lat3 * GeoKitConstants.radiansToDegrees,
            longitude: Coordinates.normalizeLongitude(lon3 * GeoKitConstants.radiansToDegrees)
        )
    }

    /// Destination point given distance, bearing, and Earth radius.
    public static func destination(
        from point: LatLon,
        distance: Double,
        bearingDegrees: Double,
        radius: Double = GeoKitConstants.earthRadiusMeters
    ) -> LatLon {
        if distance == 0 { return point }

        let latRad = point.latitude * GeoKitConstants.degreesToRadians
        let lonRad = point.longitude * GeoKitConstants.degreesToRadians
        let bearingRad = bearingDegrees * GeoKitConstants.degreesToRadians
        let angularDistance = distance / radius

        let lat2Rad = asin(
            sin(latRad) * cos(angularDistance)
                + cos(latRad) * sin(angularDistance) * cos(bearingRad)
        )

        let lon2Rad = lonRad + atan2(
            sin(bearingRad) * sin(angularDistance) * cos(latRad),
            cos(angularDistance) - sin(latRad) * sin(lat2Rad)
        )

        return LatLon(
            latitude: lat2Rad * GeoKitConstants.radiansToDegrees,
            longitude: Coordinates.normalizeLongitude(lon2Rad * GeoKitConstants.radiansToDegrees)
        )
    }

    public static func destinationMeters(
        from point: LatLon,
        distance: Double,
        bearingDegrees: Double
    ) -> LatLon {
        destination(from: point, distance: distance, bearingDegrees: bearingDegrees)
    }

    public static func destinationKm(
        from point: LatLon,
        distance: Double,
        bearingDegrees: Double
    ) -> LatLon {
        destination(
            from: point,
            distance: distance,
            bearingDegrees: bearingDegrees,
            radius: GeoKitConstants.earthRadiusKm
        )
    }

    public static func destinationMiles(
        from point: LatLon,
        distance: Double,
        bearingDegrees: Double
    ) -> LatLon {
        destination(
            from: point,
            distance: distance,
            bearingDegrees: bearingDegrees,
            radius: GeoKitConstants.earthRadiusMiles
        )
    }

    /// Uniform random point inside a circle (meters).
    public static func randomPointInCircle(from center: LatLon, radiusMeters: Double) -> LatLon {
        let bearing = Double.random(in: 0..<360)
        let distance = sqrt(Double.random(in: 0...1)) * radiusMeters
        return destinationMeters(from: center, distance: distance, bearingDegrees: bearing)
    }

    /// Uniform random point inside a circle (kilometers).
    public static func randomPointInCircleKm(from center: LatLon, radiusKm: Double) -> LatLon {
        randomPointInCircle(from: center, radiusMeters: radiusKm * 1000)
    }

    private static func normalizeDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: GeoKitConstants.degreesInCircle)
        if value < 0 { value += GeoKitConstants.degreesInCircle }
        return value
    }
}
