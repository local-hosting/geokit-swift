#if canImport(SwiftUI)
import GeoKitContract
import SwiftUI

@MainActor
public enum GeoKitMapProviderContentRegistry {
    public typealias Builder = @MainActor (MapContentRequest) -> AnyView

    private static var builders: [MapProviderId: Builder] = [:]

    public static func register(_ provider: MapProviderId, builder: @escaping Builder) {
        builders[provider] = builder
    }

    public static func content(for request: MapContentRequest) -> AnyView? {
        let provider = GeoKitMapProviderRegistry.resolve(for: request)
        return builders[provider]?(request)
    }

    public static func resetForTesting() {
        builders.removeAll()
    }
}
#endif
