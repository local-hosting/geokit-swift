import Foundation

public struct MapboxProviderConfig: Sendable, Equatable {
    public var accessToken: String?
    public var styleURI: String?

    public init(accessToken: String? = nil, styleURI: String? = nil) {
        self.accessToken = accessToken
        self.styleURI = styleURI
    }
}

public struct AppleMapsProviderConfig: Sendable, Equatable {
    public enum MapStyle: String, Sendable, Equatable {
        case standard
        case imagery
        case hybrid
    }

    public var mapStyle: MapStyle

    public init(mapStyle: MapStyle = .standard) {
        self.mapStyle = mapStyle
    }
}

/// Global map provider configuration — mirrors `@geokit/ui` `configure({ maptiler, mapbox })`.
public enum GeoKitMapProviderRegistry {
    private static var configuredProvider: MapProviderId?
    private static var mapboxConfig = MapboxProviderConfig()
    private static var appleConfig = AppleMapsProviderConfig()

    public static var defaultProvider: MapProviderId {
        configuredProvider ?? MapProviderResolver.fromEnvironment()
    }

    public static var mapbox: MapboxProviderConfig { mapboxConfig }
    public static var apple: AppleMapsProviderConfig { appleConfig }

    public static func configure(
        provider: MapProviderId? = nil,
        mapbox: MapboxProviderConfig? = nil,
        apple: AppleMapsProviderConfig? = nil
    ) {
        if let provider {
            configuredProvider = provider
        }
        if let mapbox {
            mapboxConfig = mapbox
        }
        if let apple {
            appleConfig = apple
        }
    }

    public static func resolve(for request: MapContentRequest) -> MapProviderId {
        request.mapProviderId ?? defaultProvider
    }

    public static func resetForTesting() {
        configuredProvider = nil
        mapboxConfig = MapboxProviderConfig()
        appleConfig = AppleMapsProviderConfig()
    }
}
