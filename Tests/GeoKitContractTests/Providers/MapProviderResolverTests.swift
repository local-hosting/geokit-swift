import GeoKitContract
import XCTest

final class MapProviderResolverTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        GeoKitMapProviderRegistry.resetForTesting()
    }

    func testParseKnownProviders() throws {
        XCTAssertEqual(try MapProviderResolver.parse("mapbox"), .mapbox)
        XCTAssertEqual(try MapProviderResolver.parse("apple"), .apple)
        XCTAssertEqual(try MapProviderResolver.parse("mapkit"), .apple)
    }

    func testParseUnknownProviderThrows() {
        XCTAssertThrowsError(try MapProviderResolver.parse("google")) { error in
            XCTAssertEqual(error as? MapProviderConfigurationError, .unknownProvider("google"))
        }
    }

    func testResolveStyleURIInfersMapbox() {
        let request = MapContentRequest(
            id: "city-lights",
            phase: .snapshot,
            isExpanded: false,
            mapStyleURI: "mapbox://styles/corio/demo"
        )
        XCTAssertEqual(MapProviderResolver.resolve(for: request), .mapbox)
    }

    func testFromEnvironmentUsesExplicitKey() {
        let provider = MapProviderResolver.fromEnvironment(
            environment: ["GEOKIT_MAP_PROVIDER": "apple"],
            infoPlistValue: nil
        )
        XCTAssertEqual(provider, .apple)
    }

    func testRegistryConfigureOverridesDefault() {
        GeoKitMapProviderRegistry.configure(provider: .apple)
        XCTAssertEqual(GeoKitMapProviderRegistry.defaultProvider, .apple)
    }

    func testRegistryResolvePrefersRequestOverride() {
        GeoKitMapProviderRegistry.configure(provider: .mapbox)
        let request = MapContentRequest(
            id: "card-1",
            phase: .live,
            isExpanded: true,
            mapProviderId: .apple
        )
        XCTAssertEqual(GeoKitMapProviderRegistry.resolve(for: request), .apple)
    }
}
