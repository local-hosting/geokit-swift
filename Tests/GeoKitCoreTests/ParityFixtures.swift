import Foundation
import GeoKitContract
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


    struct TurfPolygonFixture: Decodable {
        let type: String
        let coordinates: [[[Double]]]

        var polygon: GeoJSONPolygon {
            GeoJSONPolygon(coordinates: coordinates)
        }
    }

    struct TurfPointFixture: Decodable {
        let latitude: Double
        let longitude: Double

        var latLon: LatLon { LatLon(latitude: latitude, longitude: longitude) }
    }

    struct TurfContainmentPointFixture: Decodable {
        let point: TurfPointFixture
        let polygon: TurfPolygonFixture
        let expected: Bool
    }

    struct TurfContainmentBoundsPointFixture: Decodable {
        let bounds: [Double]
        let point: TurfPointFixture
        let expected: Bool
    }

    struct TurfContainmentBoundsFixture: Decodable {
        let outer: [Double]
        let inner: [Double]
        let expected: Bool
    }

    struct TurfContainmentIntersectFixture: Decodable {
        let bounds1: [Double]
        let bounds2: [Double]
        let expected: Bool
    }

    struct TurfContainmentSection: Decodable {
        let pointInside: TurfContainmentPointFixture
        let pointOutside: TurfContainmentPointFixture
        let boundsContainsPoint: TurfContainmentBoundsPointFixture
        let boundsContainsBounds: TurfContainmentBoundsFixture
        let boundsIntersects: TurfContainmentIntersectFixture
    }

    struct TurfCentroidExpected: Decodable {
        let latitude: Double
        let longitude: Double
    }

    struct TurfCentroidPolygonFixture: Decodable {
        let polygon: TurfPolygonFixture
        let expected: TurfCentroidExpected
        let tolerance: Double
    }

    struct TurfCentroidPointsFixture: Decodable {
        let points: [TurfPointFixture]
        let expected: TurfCentroidExpected
        let tolerance: Double
    }

    struct TurfCentroidSection: Decodable {
        let polygon: TurfCentroidPolygonFixture
        let points: TurfCentroidPointsFixture
    }

    struct TurfAreaPolygonFixture: Decodable {
        let polygon: TurfPolygonFixture
        let expectedM2: Double
        let toleranceM2: Double
    }

    struct TurfAreaBoundsFixture: Decodable {
        let bounds: [Double]
        let expectedM2: Double
        let toleranceM2: Double
    }

    struct TurfAreaSection: Decodable {
        let polygonM2: TurfAreaPolygonFixture
        let boundsM2: TurfAreaBoundsFixture
    }

    struct TurfLengthLineFixture: Decodable {
        let coordinates: [TurfPointFixture]
        let expectedMeters: Double
        let toleranceMeters: Double
    }

    struct TurfLengthPerimeterFixture: Decodable {
        let polygon: TurfPolygonFixture
        let expectedMeters: Double
        let toleranceMeters: Double
    }

    struct TurfLengthSection: Decodable {
        let lineMeters: TurfLengthLineFixture
        let perimeterMeters: TurfLengthPerimeterFixture
    }

    struct TurfBufferPointFixture: Decodable {
        let point: TurfPointFixture
        let radiusMeters: Double
        let steps: Int
        let expectedRingCount: Int
        let expectedAreaM2: Double
        let areaToleranceM2: Double
    }

    struct TurfBufferSection: Decodable {
        let point1km: TurfBufferPointFixture
    }

    struct TurfDMSExpected: Decodable {
        let degrees: Int
        let minutes: Int
        let seconds: Double
        let direction: String
    }

    struct TurfDMSFixture: Decodable {
        let decimal: Double
        let isLongitude: Bool
        let expected: TurfDMSExpected
    }

    struct TurfConversionsSection: Decodable {
        let nycLatitudeDms: TurfDMSFixture
        let nycLongitudeDms: TurfDMSFixture
    }

    struct TurfBoundsGeoBboxFixture: Decodable {
        let bounds: [Double]
        let expectedFirstPoint: TurfPointFixture
    }

    struct TurfBoundsGeoGeometryFixture: Decodable {
        let polygon: TurfPolygonFixture
        let expected: [Double]
    }

    struct TurfBoundsGeoSection: Decodable {
        let bboxToPolygon: TurfBoundsGeoBboxFixture
        let geometryBounds: TurfBoundsGeoGeometryFixture
    }

    struct TurfSection: Decodable {
        let containment: TurfContainmentSection
        let centroid: TurfCentroidSection
        let area: TurfAreaSection
        let length: TurfLengthSection
        let buffer: TurfBufferSection
        let conversions: TurfConversionsSection
        let boundsGeo: TurfBoundsGeoSection
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

    struct OfflineBoundsFixture: Decodable {
        let south: Double
        let west: Double
        let north: Double
        let east: Double

        var bounds: MapOfflineBounds {
            MapOfflineBounds(south: south, west: west, north: north, east: east)
        }
    }

    struct OfflineDefaultsFixture: Decodable {
        let webMaxPrefetchZoom: Int
        let webMaxTileCount: Int
        let nativeMapboxMaxPrefetchZoom: Int
        let liveMapCoverageThreshold: Double
        let snapshotFallbackCoverageThreshold: Double
    }

    struct OfflineZoomClampFixture: Decodable {
        let bounds: OfflineBoundsFixture
        let inputMinZoom: Int
        let inputMaxZoom: Int
        let expectedMaxZoom: Int
    }

    struct OfflineTileCountFixture: Decodable {
        let bounds: OfflineBoundsFixture
        let minZoom: Int
        let maxZoom: Int
        let expected: Int
        let enumerated: Int
    }

    struct OfflineCoverageFixture: Decodable {
        let tilesCached: Int
        let tilesRequired: Int
        let policy: String
        let recommendsLiveMap: Bool
        let recommendsSnapshotFallback: Bool
        let status: String
    }

    struct OfflineOversizedFixture: Decodable {
        let bounds: OfflineBoundsFixture
        let minZoom: Int
        let maxZoom: Int
        let maxTileCount: Int
        let expectedError: String
    }

    struct OfflineSection: Decodable {
        let defaults: OfflineDefaultsFixture
        let webZoomClamp: OfflineZoomClampFixture
        let tileCount: OfflineTileCountFixture
        let sparseCoverage: OfflineCoverageFixture
        let liveCoverage: OfflineCoverageFixture
        let oversizedPrefetch: OfflineOversizedFixture
    }

    let coordinates: [String: CoordinateFixture]
    let bounds: BoundsSection
    let distance: DistanceSection
    let bearing: BearingSection
    let h3: H3Section
    let validation: [String: ValidationFixture]
    let geohash: GeohashSection
    let geojson: GeoJSONSection
    let turf: TurfSection
    let offline: OfflineSection

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
