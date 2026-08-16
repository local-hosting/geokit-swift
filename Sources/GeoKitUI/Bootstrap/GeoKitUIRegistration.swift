#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

@MainActor
public enum GeoKitUIRegistration {
    public static func activate() {
        GeoKitAppleProviderRegistration.activate()
    }

    public static func resetForTesting() {
        GeoKitAppleProviderRegistration.resetForTesting()
        GeoKitMapProviderContentRegistry.resetForTesting()
        GeoKitSnapshotCaptureRegistry.resetForTesting()
        GeoKitMapProviderBootstrapRegistry.resetForTesting()
        GeoKitMapBootstrap.resetForTesting()
    }
}
#endif
