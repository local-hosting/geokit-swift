import GeoKitContract

public enum GeoKitMapProviderBootstrapRegistry {
    private static var prepareHandlers: [MapProviderId: () -> Void] = [:]

    public static func register(_ provider: MapProviderId, prepare: @escaping () -> Void) {
        prepareHandlers[provider] = prepare
    }

    public static func prepare(_ provider: MapProviderId) {
        prepareHandlers[provider]?()
    }

    public static func resetForTesting() {
        prepareHandlers.removeAll()
    }
}
