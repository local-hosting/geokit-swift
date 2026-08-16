import Foundation

/// Which map backends GeoKit links and registers per platform.
public enum GeoKitMapPlatformSupport {
    /// Native Apple MapKit live surfaces and snapshots.
    public static var supportsAppleMapKit: Bool {
        #if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)
        true
        #else
        false
        #endif
    }

    /// Mapbox Maps SDK live surfaces (iOS — includes CarPlay — and native visionOS; Catalyst uses the iOS slice).
    public static var supportsMapbox: Bool {
        #if os(iOS) || os(visionOS)
        true
        #else
        false
        #endif
    }

    /// Suggested default when the host has not called `GeoKitMapProviderRegistry.configure(provider:)`.
    public static var defaultProvider: MapProviderId {
        MapProviderResolver.defaultForPlatform()
    }
}
