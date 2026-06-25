#if os(iOS)
import MapboxCommon

public enum GeoKitMapBootstrap {
    /// Silence Mapbox console noise and opt out of optional location telemetry before any map mounts.
    public static func prepareMapbox() {
        _ = GeoKitMapboxConfiguration.telemetryOptOut
        _ = GeoKitMapboxLogging.configureOnce
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
