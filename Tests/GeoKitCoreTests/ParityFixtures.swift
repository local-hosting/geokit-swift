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

    struct BearingMidpointFixture: Decodable {
        let from: String
        let to: String
        let expected: CoordinateFixture
        let toleranceDegrees: Double
    }

    struct BearingDestinationFixture: Decodable {
        let from: String
        let distanceMeters: Double
        let bearingDegrees: Double
        let expected: CoordinateFixture
        let toleranceDegrees: Double
    }

    struct H3Fixture: Decodable {
        let latitude: Double
        let longitude: Double
        let resolution: Int
        let expectedCell: String
    }

    struct H3ParentFixture: Decodable {
        let cell: String
        let resolution: Int
        let expectedParent: String
    }

    struct H3ChildrenFixture: Decodable {
        let cell: String
        let resolution: Int
        let expectedChildCount: Int
    }

    struct H3NeighborsFixture: Decodable {
        let cell: String
        let k: Int
        let expectedCount: Int
        let containsCenter: Bool
        let ringNeighborAreNeighbors: Bool
    }

    struct H3MetricsFixture: Decodable {
        let resolution: Int
        let expectedEdgeLengthMeters: Double
        let expectedCellAreaM2: Double
        let edgeLengthToleranceMeters: Double
        let cellAreaToleranceM2: Double
    }

    struct GeohashEncodeFixture: Decodable {
        let from: String
        let precision: Int
        let expectedHash: String
    }

    struct GeohashDecodeFixture: Decodable {
        let hash: String
        let expected: CoordinateFixture
        let tolerance: Double
    }

    struct GeohashBoundsFixture: Decodable {
        let hash: String
        let expected: [Double]
    }

    struct GeohashNeighborsExpected: Decodable {
        let n: String
        let ne: String
        let e: String
        let se: String
        let s: String
        let sw: String
        let w: String
        let nw: String
    }

    struct GeohashNeighborsFixture: Decodable {
        let hash: String
        let expected: GeohashNeighborsExpected
        let expectedArray: [String]
    }

    struct GeohashValidationFixture: Decodable {
        let validHash: String
        let invalidHash: String
        let validExpected: Bool
        let invalidExpected: Bool
    }

    struct GeohashSection: Decodable {
        let encodeNycRes9: GeohashEncodeFixture
        let decodeRes9: GeohashDecodeFixture
        let boundsRes5: GeohashBoundsFixture
        let neighborsRes5: GeohashNeighborsFixture
        let validation: GeohashValidationFixture
    }

    struct GeoJSONSection: Decodable {
        let pointCoordinates: [Double]
        let expectedFeatureId: String
        let openRingCoordinates: [[Double]]
        let expectedClosedRingCount: Int

        func sampleFeature() -> GeoJSONFeature {
            GeoJSONFeature(
                geometry: .point(GeoJSONPoint(coordinates: pointCoordinates)),
                properties: [
                    "id": .string(expectedFeatureId),
                    "name": .string("NYC"),
                ]
            )
        }
    }

    struct ValidationFixture: Decodable {
        let latitude: Double
        let longitude: Double
        let expected: Bool
    }

    let coordinates: [String: CoordinateFixture]
    let bounds: BoundsSection
    let distance: DistanceSection
    let bearing: BearingSection
    let h3: H3Section
    let validation: [String: ValidationFixture]
    let geohash: GeohashSection
    let geojson: GeoJSONSection

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

    struct BearingSection: Decodable {
        let east: BearingFixture
        let north: BearingFixture
        let midpointNycLa: BearingMidpointFixture
        let destination1kmEast: BearingDestinationFixture
    }

    struct H3Section: Decodable {
        let nycRes9: H3Fixture
        let parentRes8: H3ParentFixture
        let childrenRes10: H3ChildrenFixture
        let neighborsK1: H3NeighborsFixture
        let metricsRes9: H3MetricsFixture
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
