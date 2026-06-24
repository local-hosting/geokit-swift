import Foundation

public enum Bearing {
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

    /// Final bearing at the destination point.
    public static func final(from: LatLon, to: LatLon) -> Double {
        normalizeDegrees(initial(from: to, to: from) + 180)
    }

    private static func normalizeDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: GeoKitConstants.degreesInCircle)
        if value < 0 { value += GeoKitConstants.degreesInCircle }
        return value
    }
}
