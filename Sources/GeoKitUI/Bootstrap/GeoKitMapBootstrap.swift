#if os(iOS)
import GeoKitContract

public enum GeoKitMapBootstrap {
    private static var preparedProvider: MapProviderId?

    /// Prepare the configured map provider before any map mounts.
    public static func prepare(provider: MapProviderId? = nil) {
        let resolved = provider ?? GeoKitMapProviderRegistry.defaultProvider
        guard preparedProvider != resolved else { return }
        preparedProvider = resolved
        GeoKitMapProviderBootstrapRegistry.prepare(resolved)
    }

    public static func resetForTesting() {
        preparedProvider = nil
    }
}
#endif
