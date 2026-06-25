import Foundation
import Turf

public enum Length {
    public static func lineLengthMeters(_ coordinates: [LatLon]) -> Double {
        guard coordinates.count >= 2,
              let lineString = TurfBridge.turfLineString(from: coordinates),
              let distance = lineString.distance() else {
            return 0
        }

        guard distance.isFinite, distance >= 0 else { return 0 }
        return distance
    }

    public static func lineLengthMeters(_ lineString: GeoJSONLineString) -> Double {
        guard let turfLineString = TurfBridge.turfLineString(from: lineString),
              let distance = turfLineString.distance() else {
            return 0
        }

        guard distance.isFinite, distance >= 0 else { return 0 }
        return distance
    }

    public static func lineLengthKm(_ coordinates: [LatLon]) -> Double {
        lineLengthMeters(coordinates) / GeoKitConstants.metersToKilometers
    }

    public static func lineLengthKm(_ lineString: GeoJSONLineString) -> Double {
        lineLengthMeters(lineString) / GeoKitConstants.metersToKilometers
    }

    public static func lineLengthMiles(_ coordinates: [LatLon]) -> Double {
        lineLengthMeters(coordinates) / GeoKitConstants.metersToMiles
    }

    public static func lineLengthMiles(_ lineString: GeoJSONLineString) -> Double {
        lineLengthMeters(lineString) / GeoKitConstants.metersToMiles
    }

    public static func perimeterMeters(_ polygon: GeoJSONPolygon) -> Double {
        guard let ring = polygon.coordinates.first else { return 0 }

        let latLonRing = ring.map { position in
            LatLon(latitude: position[1], longitude: position[0])
        }

        return lineLengthMeters(latLonRing)
    }

    public static func perimeterKm(_ polygon: GeoJSONPolygon) -> Double {
        perimeterMeters(polygon) / GeoKitConstants.metersToKilometers
    }

    public static func perimeterMiles(_ polygon: GeoJSONPolygon) -> Double {
        perimeterMeters(polygon) / GeoKitConstants.metersToMiles
    }
}
