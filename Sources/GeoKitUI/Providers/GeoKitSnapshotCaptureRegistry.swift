#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

import CoreGraphics
import GeoKitContract

@MainActor
public enum GeoKitSnapshotCaptureRegistry {
    public enum CaptureError: Error, CustomStringConvertible {
        case noHandler(MapProviderId)

        public var description: String {
            switch self {
            case .noHandler(let provider):
                "no snapshot capture handler registered for provider \(provider.rawValue)"
            }
        }
    }

    public typealias Handler = @MainActor (
        MapContentRequest,
        CGSize,
        MapSnapshotPriority
    ) async throws -> GeoKitPlatformImage?

    private static var handlers: [MapProviderId: Handler] = [:]

    public static func register(_ provider: MapProviderId, handler: @escaping Handler) {
        handlers[provider] = handler
    }

    public static func capture(
        request: MapContentRequest,
        size: CGSize,
        priority: MapSnapshotPriority = .background
    ) async throws -> GeoKitPlatformImage? {
        let provider = MapProviderResolver.resolve(for: request)
        var resolved = request
        resolved.mapProviderId = provider
        guard let handler = handlers[provider] else {
            throw CaptureError.noHandler(provider)
        }
        return try await handler(resolved, size, priority)
    }

    public static func resetForTesting() {
        handlers.removeAll()
    }
}
#endif
