import Foundation

public struct DMS: Equatable, Sendable {
    public var degrees: Int
    public var minutes: Int
    public var seconds: Double
    public var direction: CardinalDirection

    public enum CardinalDirection: String, Equatable, Sendable {
        case north = "N"
        case south = "S"
        case east = "E"
        case west = "W"
    }

    public init(degrees: Int, minutes: Int, seconds: Double, direction: CardinalDirection) {
        self.degrees = degrees
        self.minutes = minutes
        self.seconds = seconds
        self.direction = direction
    }
}

public struct DMSCoordinatePair: Equatable, Sendable {
    public var latitude: DMS
    public var longitude: DMS

    public init(latitude: DMS, longitude: DMS) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public enum Conversions {
    public static func toDMS(_ decimal: Double, isLongitude: Bool = false) -> DMS {
        let absolute = abs(decimal)
        let degrees = Int(floor(absolute))
        let minutesDecimal = (absolute - Double(degrees)) * GeoKitConstants.secondsPerMinute
        let minutes = Int(floor(minutesDecimal))
        let seconds = (minutesDecimal - Double(minutes)) * GeoKitConstants.secondsPerMinute

        let direction: DMS.CardinalDirection
        if isLongitude {
            direction = decimal >= 0 ? .east : .west
        } else {
            direction = decimal >= 0 ? .north : .south
        }

        return DMS(degrees: degrees, minutes: minutes, seconds: seconds, direction: direction)
    }

    public static func fromDMS(_ dms: DMS) -> Double {
        var decimal = Double(dms.degrees)
            + Double(dms.minutes) / GeoKitConstants.secondsPerMinute
            + dms.seconds / GeoKitConstants.secondsPerDegree

        switch dms.direction {
        case .south, .west:
            decimal = -decimal
        case .north, .east:
            break
        }

        return decimal
    }

    public static func coordinatesToDMS(latitude: Double, longitude: Double) -> DMSCoordinatePair {
        DMSCoordinatePair(
            latitude: toDMS(latitude, isLongitude: false),
            longitude: toDMS(longitude, isLongitude: true)
        )
    }
}
