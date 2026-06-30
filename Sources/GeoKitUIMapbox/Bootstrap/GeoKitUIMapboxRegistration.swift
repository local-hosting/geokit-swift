#if os(iOS) || os(visionOS)

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
