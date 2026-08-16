import Foundation

public struct GeohashNeighbors: Equatable, Sendable {
    public var n: String
    public var ne: String
    public var e: String
    public var se: String
    public var s: String
    public var sw: String
    public var w: String
    public var nw: String

    public var array: [String] { [n, ne, e, se, s, sw, w, nw] }
}

/// Geohash helpers shaped like Node `@doppler-group/geokit` `/geohash`.
public enum Geohash {
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")
    private static let validPattern = try! NSRegularExpression(pattern: "^[0-9b-hjkmnp-z]+$")

    public static func encode(_ coordinate: LatLon, precision: Int = 10) -> String {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        var idx = 0
        var bit = 0
        var evenBit = true
        var geohash = ""
        var latMin = -90.0
        var latMax = 90.0
        var lonMin = -180.0
        var lonMax = 180.0

        while geohash.count < precision {
            if evenBit {
                let lonMid = (lonMin + lonMax) / 2
                if lon >= lonMid {
                    idx = idx * 2 + 1
                    lonMin = lonMid
                } else {
                    idx = idx * 2
                    lonMax = lonMid
                }
            } else {
                let latMid = (latMin + latMax) / 2
                if lat >= latMid {
                    idx = idx * 2 + 1
                    latMin = latMid
                } else {
                    idx = idx * 2
                    latMax = latMid
                }
            }
            evenBit.toggle()
            bit += 1
            if bit == 5 {
                geohash.append(base32[idx])
                bit = 0
                idx = 0
            }
        }
        return geohash
    }

    public static func decode(_ hash: String) throws -> LatLon {
        let bounds = try boundsBox(hash)
        let lat = (bounds.minLat + bounds.maxLat) / 2
        let lon = (bounds.minLon + bounds.maxLon) / 2
        let latPrecision = max(0, Int(floor(2 - log10(bounds.maxLat - bounds.minLat))))
        let lonPrecision = max(0, Int(floor(2 - log10(bounds.maxLon - bounds.minLon))))
        let roundedLat = round(lat * pow(10, Double(latPrecision))) / pow(10, Double(latPrecision))
        let roundedLon = round(lon * pow(10, Double(lonPrecision))) / pow(10, Double(lonPrecision))
        return LatLon(latitude: roundedLat, longitude: roundedLon)
    }

    public static func bounds(_ hash: String) throws -> Bounds {
        let box = try boundsBox(hash)
        return [box.minLon, box.minLat, box.maxLon, box.maxLat]
    }

    public static func neighbors(_ hash: String) throws -> GeohashNeighbors {
        GeohashNeighbors(
            n: try adjacent(hash, direction: .north),
            ne: try adjacent(try adjacent(hash, direction: .north), direction: .east),
            e: try adjacent(hash, direction: .east),
            se: try adjacent(try adjacent(hash, direction: .south), direction: .east),
            s: try adjacent(hash, direction: .south),
            sw: try adjacent(try adjacent(hash, direction: .south), direction: .west),
            w: try adjacent(hash, direction: .west),
            nw: try adjacent(try adjacent(hash, direction: .north), direction: .west)
        )
    }

    public static func neighborsArray(_ hash: String) throws -> [String] {
        try neighbors(hash).array
    }

    public enum CardinalDirection: String, Sendable {
        case north = "n"
        case south = "s"
        case east = "e"
        case west = "w"
    }

    public static func neighbor(_ hash: String, direction: CardinalDirection) throws -> String {
        try adjacent(hash, direction: direction)
    }

    public static func isValid(_ hash: String) -> Bool {
        guard !hash.isEmpty else { return false }
        let range = NSRange(hash.startIndex..<hash.endIndex, in: hash)
        guard validPattern.firstMatch(in: hash, range: range) != nil else { return false }
        do {
            _ = try boundsBox(hash)
            let decoded = try decode(hash)
            return decoded.latitude >= GeoKitConstants.minLatitude
                && decoded.latitude <= GeoKitConstants.maxLatitude
                && decoded.longitude >= GeoKitConstants.minLongitude
                && decoded.longitude <= GeoKitConstants.maxLongitude
        } catch {
            return false
        }
    }

    public static func hashesInBounds(_ bounds: Bounds, precision: Int) throws -> [String] {
        guard bounds.count == 4 else { throw GeohashError.invalidBounds }
        let minLon = bounds[0]
        let minLat = bounds[1]
        let maxLon = bounds[2]
        let maxLat = bounds[3]
        var hashes = Set<String>()
        let steps = min(100, Int(pow(2.0, Double(precision))))
        let latStep = (maxLat - minLat) / Double(steps)
        let lonStep = (maxLon - minLon) / Double(steps)
        var lat = minLat
        while lat <= maxLat {
            var lon = minLon
            while lon <= maxLon {
                hashes.insert(encode(LatLon(latitude: lat, longitude: lon), precision: precision))
                lon += lonStep
            }
            lat += latStep
        }
        return Array(hashes).sorted()
    }

    private struct BoundsBox {
        var minLat: Double
        var minLon: Double
        var maxLat: Double
        var maxLon: Double
    }

    private static func boundsBox(_ hash: String) throws -> BoundsBox {
        guard !hash.isEmpty else { throw GeohashError.invalidHash(hash) }
        let normalized = hash.lowercased()
        var evenBit = true
        var latMin = -90.0
        var latMax = 90.0
        var lonMin = -180.0
        var lonMax = 180.0

        for character in normalized {
            guard let idx = base32.firstIndex(of: character) else {
                throw GeohashError.invalidHash(hash)
            }
            let value = base32.distance(from: base32.startIndex, to: idx)
            for bit in stride(from: 4, through: 0, by: -1) {
                let bitN = (value >> bit) & 1
                if evenBit {
                    let lonMid = (lonMin + lonMax) / 2
                    if bitN == 1 { lonMin = lonMid } else { lonMax = lonMid }
                } else {
                    let latMid = (latMin + latMax) / 2
                    if bitN == 1 { latMin = latMid } else { latMax = latMid }
                }
                evenBit.toggle()
            }
        }
        return BoundsBox(minLat: latMin, minLon: lonMin, maxLat: latMax, maxLon: lonMax)
    }

    private static func adjacent(_ hash: String, direction: CardinalDirection) throws -> String {
        let normalized = hash.lowercased()
        guard !normalized.isEmpty else { throw GeohashError.invalidHash(hash) }

        let neighbour: [CardinalDirection: [String]] = [
            .north: ["p0r21436x8zb9dcf5h7kjnmqesgutwvy", "bc01fg45238967deuvhjyznpkmstqrwx"],
            .south: ["14365h7k9dcfesgujnmqp0r2twvyx8zb", "238967debc01fg45kmstqrwxuvhjyznp"],
            .east: ["bc01fg45238967deuvhjyznpkmstqrwx", "p0r21436x8zb9dcf5h7kjnmqesgutwvy"],
            .west: ["238967debc01fg45kmstqrwxuvhjyznp", "14365h7k9dcfesgujnmqp0r2twvyx8zb"],
        ]
        let border: [CardinalDirection: [String]] = [
            .north: ["prxz", "bcfguvyz"],
            .south: ["028b", "0145hjnp"],
            .east: ["bcfguvyz", "prxz"],
            .west: ["0145hjnp", "028b"],
        ]

        let lastChar = String(normalized.suffix(1))
        var parent = String(normalized.dropLast())
        let type = normalized.count % 2
        if border[direction]![type].contains(lastChar), !parent.isEmpty {
            parent = try adjacent(parent, direction: direction)
        }
        let lookup = neighbour[direction]![type]
        guard let charIndex = lookup.firstIndex(of: Character(lastChar)) else {
            throw GeohashError.invalidHash(hash)
        }
        let offset = lookup.distance(from: lookup.startIndex, to: charIndex)
        return parent + String(base32[offset])
    }
}

public enum GeohashError: Error, Equatable {
    case invalidHash(String)
    case invalidBounds
}
