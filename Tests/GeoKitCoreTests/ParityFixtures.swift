import Foundation
import GeoKitCore

struct ParityFixtures: Decodable {
    struct CoordinateFixture: Decodable {
        let latitude: Double
        let longitude: Double

        var latLon: LatLon {
            LatLon(latitude: latitude, longitude: longitude)
        }
    }

    struct BoundsPairFixture: Decodable {
        let points: [CoordinateFixture]
        let expected: [Double]
    }

    struct CenterFromBoundsFixture: Decodable {
        let bounds: [Double]
        let center: CoordinateFixture
    }

    struct CenterAndZoomExpected: Decodable {
        let latitude: Double
        let longitude: Double
        let zoom: Double
    }

    struct CenterAndZoomFixture: Decodable {
        let bounds: [Double]
        let expected: CenterAndZoomExpected
    }

    struct DistanceRangeFixture: Decodable {
        let from: String
        let to: String
        let minMeters: Double
        let maxMeters: Double
    }

    struct DistanceExactFixture: Decodable {
        let from: String
        let to: String
        let expectedMeters: Double
    }

    struct DistanceWithinFixture: Decodable {
        let from: String
        let to: String
        let thresholdMeters: Double
        let expectedWithin: Bool
    }

    struct BearingFixture: Decodable {
        let from: CoordinateFixture
        let to: CoordinateFixture
        let expectedDegrees: Double
        let toleranceDegrees: Double
    }

    struct H3Fixture: Decodable {
        let latitude: Double
        let longitude: Double
        let resolution: Int
        let expectedCell: String
    }

    struct ValidationFixture: Decodable {
        let latitude: Double
        let longitude: Double
        let expected: Bool
    }

    let coordinates: [String: CoordinateFixture]
    let bounds: BoundsSection
    let distance: DistanceSection
    let bearing: [String: BearingFixture]
    let h3: [String: H3Fixture]
    let validation: [String: ValidationFixture]

    struct BoundsSection: Decodable {
        let nycPair: BoundsPairFixture
        let centerFromBounds: CenterFromBoundsFixture
        let centerAndZoom: CenterAndZoomFixture
    }

    struct DistanceSection: Decodable {
        let nycToLaMeters: DistanceRangeFixture
        let samePointMeters: DistanceExactFixture
        let nearbyWithin1km: DistanceWithinFixture
    }

    static func load() throws -> ParityFixtures {
        let url = Bundle.module.url(forResource: "parity-fixtures", withExtension: "json")!
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ParityFixtures.self, from: data)
    }

    func coordinate(named name: String) -> LatLon {
        coordinates[name]!.latLon
    }
}
