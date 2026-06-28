#if os(iOS)
@MainActor
public enum GeoKitUIMapboxRegistration {
    public static func activate() {
        GeoKitMapboxBootstrap.activate()
    }

    public static func resetForTesting() {
        GeoKitMapboxBootstrap.resetForTesting()
    }
}
#endif
