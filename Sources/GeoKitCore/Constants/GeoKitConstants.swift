import Foundation

public enum GeoKitConstants {
    public static let earthRadiusMeters = 6_371_000.0
    public static let earthRadiusKm = 6_371.0
    public static let earthRadiusMiles = 3_959.0

    public static let minLatitude = -90.0
    public static let maxLatitude = 90.0
    public static let minLongitude = -180.0
    public static let maxLongitude = 180.0

    public static let degreesToRadians = Double.pi / 180.0
    public static let radiansToDegrees = 180.0 / Double.pi
    public static let degreesInCircle = 360.0

    public static let metersToKilometers = 1_000.0
    public static let metersToMiles = 1_609.34
    public static let squareMetersToSquareKilometers = 1_000_000.0
    public static let squareMetersToSquareMiles = 2_589_988.110336
    public static let squareMetersToAcres = 4_046.8564224
    public static let secondsPerMinute = 60.0
    public static let secondsPerDegree = 3_600.0
    public static let defaultBufferSteps = 64
}
