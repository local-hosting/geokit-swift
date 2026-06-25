#if os(iOS)
import GeoKitContract
import MapboxCommon

public enum GeoKitMapBootstrap {
    private static var preparedProvider: MapProviderId?

    /// Prepare the configured map provider before any map mounts.
    public static func prepare(provider: MapProviderId? = nil) {
        let resolved = provider ?? GeoKitMapProviderRegistry.defaultProvider
        guard preparedProvider != resolved else { return }
        preparedProvider = resolved

        switch resolved {
        case .mapbox:
            prepareMapbox()
        case .apple:
            break
        }
    }

    /// Silence Mapbox console noise and opt out of optional location telemetry before any map mounts.
    public static func prepareMapbox() {
        _ = GeoKitMapboxConfiguration.telemetryOptOut
        _ = GeoKitMapboxLogging.configureOnce
    }

    public static func resetForTesting() {
        preparedProvider = nil
    }
}

private enum GeoKitMapboxConfiguration {
    static let telemetryOptOut: Void = {
        UserDefaults.standard.register(defaults: ["MGLMapboxMetricsEnabled": false])
        UserDefaults.standard.set(false, forKey: "MGLMapboxMetricsEnabled")
    }()
}

private enum GeoKitMapboxLogging {
    static let configureOnce: Void = {
        LogConfiguration.setLoggingLevelForUpTo(nil)
    }()
}
#endif
