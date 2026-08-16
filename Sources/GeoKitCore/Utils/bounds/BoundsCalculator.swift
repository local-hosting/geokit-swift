import Foundation

public enum BoundsCalculator {
    /// Compute bounds `[minLon, minLat, maxLon, maxLat]` from latitude/longitude pairs.
    public static func fromCoordinates(_ coordinates: [LatLon]) -> Bounds? {
        guard !coordinates.isEmpty else { return nil }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        return [minLon, minLat, maxLon, maxLat]
    }

    /// Center of a bounds box as `[lat, lon]`, matching Node geokit `getCenter` for axis-aligned boxes.
    public static func center(of bounds: Bounds) -> LatLon? {
        guard bounds.count == 4 else { return nil }

        let minLon = bounds[0]
        let minLat = bounds[1]
        let maxLon = bounds[2]
        let maxLat = bounds[3]

        guard [minLon, minLat, maxLon, maxLat].allSatisfy(\.isFinite) else { return nil }

        return LatLon(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
    }

    /// Port of Node `@geokit/bounds` `calculateZoomFromBounds`.
    public static func zoom(from bounds: Bounds) -> Double {
        guard bounds.count == 4 else { return 10 }

        let minLon = bounds[0]
        let minLat = bounds[1]
        let maxLon = bounds[2]
        let maxLat = bounds[3]

        let latDiff = maxLat - minLat
        let lonDiff = maxLon - minLon
        let maxDiff = max(latDiff, lonDiff)

        if maxDiff == 0 || (maxDiff < 0.0001 && maxDiff >= 0) {
            return 10
        }

        if maxDiff > 60 { return 3 }
        if maxDiff > 30 { return 4 }
        if maxDiff > 15 { return 5 }
        if maxDiff > 8 { return 6 }
        if maxDiff > 4 { return 7 }
        if maxDiff > 2 { return 8 }
        if maxDiff > 1 { return 9 }
        if maxDiff > 0.5 { return 10 }
        if maxDiff > 0.25 { return 11 }
        if maxDiff > 0.1 { return 12 }
        if maxDiff > 0.05 { return 13 }
        if maxDiff > 0.025 { return 14 }
        if maxDiff > 0.01 { return 15 }
        if maxDiff > 0.005 { return 16 }
        if maxDiff > 0.0025 { return 17 }
        return 18
    }

    /// Port of Node `@geokit/bounds` `calculateCenterAndZoom`.
    public static func centerAndZoom(from bounds: Bounds) -> CenterAndZoom? {
        guard bounds.count == 4, let center = center(of: bounds) else { return nil }
        return CenterAndZoom(
            latitude: center.latitude,
            longitude: center.longitude,
            zoom: zoom(from: bounds)
        )
    }

    /// Size-aware viewport fit for map surfaces.
    public static func fitViewport(coordinates: [LatLon], mapSize: MapSize) -> ViewportFit? {
        guard let bounds = fromCoordinates(coordinates), let center = center(of: bounds) else {
            return nil
        }

        let baseZoom = zoom(from: bounds)
        guard mapSize.width > 0, mapSize.height > 0 else {
            return ViewportFit(center: center, zoom: baseZoom)
        }

        let minLon = bounds[0]
        let minLat = bounds[1]
        let maxLon = bounds[2]
        let maxLat = bounds[3]
        let lonSpan = max(maxLon - minLon, 0.000_001)
        let latSpan = max(maxLat - minLat, 0.000_001)

        let lonZoom = log2(mapSize.width * 360 / (lonSpan * 256))
        let latZoom = log2(mapSize.height * 180 / (latSpan * 256))
        let sizeAdjustedZoom = min(lonZoom, latZoom, baseZoom)

        return ViewportFit(center: center, zoom: max(0, min(22, sizeAdjustedZoom)))
    }


    /// Port of Node `@geokit/bounds` `calculateFitBoundsViewport` (Web Mercator + padding).
    public static func fitBoundsViewport(
        bounds: Bounds,
        mapSize: MapSize,
        paddingFraction: Double = 0.06
    ) -> ViewportFit? {
        guard bounds.count == 4, mapSize.width > 0, mapSize.height > 0 else { return nil }

        let minLon = bounds[0]
        let minLat = bounds[1]
        let maxLon = bounds[2]
        let maxLat = bounds[3]
        let latSpan = maxLat - minLat
        let lonSpan = maxLon - minLon
        let padLat = latSpan * paddingFraction
        let padLon = lonSpan * paddingFraction
        let padded: Bounds = [minLon - padLon, minLat - padLat, maxLon + padLon, maxLat + padLat]

        guard let center = center(of: padded) else { return nil }

        func latRad(_ lat: Double) -> Double {
            let sin = Foundation.sin(lat * .pi / 180)
            let clamped = min(max(sin, -0.9999), 0.9999)
            return Foundation.log((1 + clamped) / (1 - clamped)) / 2
        }

        let worldSize = 512.0
        let latFraction = (latRad(padded[3]) - latRad(padded[1])) / .pi
        let lonFraction = (padded[2] - padded[0]) / 360
        let latZoom = latFraction > 0 ? log2(mapSize.height / worldSize / latFraction) : 22
        let lngZoom = lonFraction > 0 ? log2(mapSize.width / worldSize / lonFraction) : 22
        let zoom = max(0, min(22, min(latZoom, lngZoom)))
        let rounded = floor(zoom * 100) / 100

        return ViewportFit(center: center, zoom: rounded)
    }

    public static func isWithin(_ bounds: Bounds, coordinate: LatLon) -> Bool {
        guard bounds.count == 4 else { return false }

        let minLon = bounds[0]
        let minLat = bounds[1]
        let maxLon = bounds[2]
        let maxLat = bounds[3]

        return coordinate.longitude >= minLon
            && coordinate.longitude <= maxLon
            && coordinate.latitude >= minLat
            && coordinate.latitude <= maxLat
    }
}
