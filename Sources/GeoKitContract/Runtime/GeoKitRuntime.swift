import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Mapbox-free contract surface linked by the host app before GeoKit.framework loads.
@MainActor
public enum GeoKitRuntime {
    #if canImport(SwiftUI)
    public typealias MapContentBuilder = @MainActor (MapContentRequest) -> AnyView

    public static var mapContent: MapContentBuilder?
    #endif

    public static var isLoaded = false

    /// Load GeoKit.framework via dlopen (implemented by host app).
    public static var loadFramework: (() -> Bool)?

    @discardableResult
    public static func loadIfNeeded() -> Bool {
        #if canImport(SwiftUI)
        if isLoaded { return mapContent != nil }
        #else
        if isLoaded { return true }
        #endif
        guard let loadFramework else { return false }
        let loaded = loadFramework()
        isLoaded = loaded
        return loaded
    }

    public static func resetForTesting() {
        isLoaded = false
        #if canImport(SwiftUI)
        mapContent = nil
        #endif
        loadFramework = nil
        LiveMapSnapshotCoordinator.resetForTesting()
    }
}
