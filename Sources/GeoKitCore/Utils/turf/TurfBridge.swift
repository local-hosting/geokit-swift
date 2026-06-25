import Foundation
import Turf

/// Converts between GeoKit types and Turf geometry primitives.
enum TurfBridge {
    static func turfCoordinate(_ latLon: LatLon) -> LocationCoordinate2D {
        LocationCoordinate2D(latitude: latLon.latitude, longitude: latLon.longitude)
    }

    static func latLon(_ coordinate: LocationCoordinate2D) -> LatLon {
        LatLon(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    static func turfCoordinates(from positions: [GeoJSONPosition]) -> [LocationCoordinate2D] {
        positions.map { position in
            LocationCoordinate2D(latitude: position[1], longitude: position[0])
        }
    }

    static func geoJSONPositions(from ring: [LocationCoordinate2D]) -> [GeoJSONPosition] {
        ring.map { coordinate in
            [coordinate.longitude, coordinate.latitude]
        }
    }

    static func turfPolygon(from geometry: GeoJSONPolygon) -> Turf.Polygon? {
        guard GeoJSONValidation.isValidPolygon(geometry) else { return nil }
        let rings = geometry.coordinates.map { turfCoordinates(from: $0) }
        return Turf.Polygon(rings)
    }

    static func geoJSONPolygon(from polygon: Turf.Polygon) -> GeoJSONPolygon {
        let rings = polygon.coordinates.map { geoJSONPositions(from: $0) }
        return GeoJSONPolygon(coordinates: rings)
    }

    static func turfLineString(from geometry: GeoJSONLineString) -> Turf.LineString? {
        guard GeoJSONValidation.isValidLineString(geometry) else { return nil }
        return Turf.LineString(turfCoordinates(from: geometry.coordinates))
    }

    static func turfLineString(from coordinates: [LatLon]) -> Turf.LineString? {
        guard coordinates.count >= 2 else { return nil }
        return Turf.LineString(coordinates.map(turfCoordinate))
    }

    static func boundingBox(from bounds: Bounds) -> Turf.BoundingBox? {
        guard bounds.count == 4 else { return nil }

        let minLon = bounds[0]
        let minLat = bounds[1]
        let maxLon = bounds[2]
        let maxLat = bounds[3]

        guard [minLon, minLat, maxLon, maxLat].allSatisfy(\.isFinite) else { return nil }

        return Turf.BoundingBox(
            southWest: LocationCoordinate2D(latitude: minLat, longitude: minLon),
            northEast: LocationCoordinate2D(latitude: maxLat, longitude: maxLon)
        )
    }

    static func bounds(from boundingBox: Turf.BoundingBox) -> Bounds {
        [
            boundingBox.southWest.longitude,
            boundingBox.southWest.latitude,
            boundingBox.northEast.longitude,
            boundingBox.northEast.latitude,
        ]
    }

    static func turfBoundingBox(from coordinates: [LatLon]) -> Turf.BoundingBox? {
        guard !coordinates.isEmpty else { return nil }
        return Turf.BoundingBox(from: coordinates.map(turfCoordinate))
    }

    static func allCoordinates(from geometry: GeoJSONGeometry) -> [LocationCoordinate2D] {
        switch geometry {
        case .point(let point):
            return turfCoordinates(from: [point.coordinates])
        case .lineString(let lineString):
            return turfCoordinates(from: lineString.coordinates)
        case .polygon(let polygon):
            return polygon.coordinates.flatMap { turfCoordinates(from: $0) }
        case .multiPoint(let multiPoint):
            return turfCoordinates(from: multiPoint.coordinates)
        case .multiLineString(let multiLineString):
            return multiLineString.coordinates.flatMap { turfCoordinates(from: $0) }
        case .multiPolygon(let multiPolygon):
            return multiPolygon.coordinates.flatMap { polygon in
                polygon.flatMap { turfCoordinates(from: $0) }
            }
        case .geometryCollection(let collection):
            return collection.geometries.flatMap { allCoordinates(from: $0) }
        }
    }
}
