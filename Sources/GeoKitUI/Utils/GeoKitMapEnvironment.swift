import SwiftUI

/// Hosts may read this preference to skip rasterization (e.g. `drawingGroup`) while a live Mapbox surface is mounted.
public struct GeoKitLiveRenderingKey: PreferenceKey {
    public static var defaultValue = false

    public static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private struct GeoKitMapSurfaceReadyKey: EnvironmentKey {
    static let defaultValue = true
}

private struct GeoKitMapIsTransitioningKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// When `false`, GeoKit defers mounting the live Mapbox view until layout is stable.
    var geokitMapSurfaceReady: Bool {
        get { self[GeoKitMapSurfaceReadyKey.self] }
        set { self[GeoKitMapSurfaceReadyKey.self] = newValue }
    }

    /// When `true`, GeoKit may show a frozen snapshot overlay during host-driven transitions.
    var geokitMapIsTransitioning: Bool {
        get { self[GeoKitMapIsTransitioningKey.self] }
        set { self[GeoKitMapIsTransitioningKey.self] = newValue }
    }
}

extension View {
    func geokitIgnoresSafeArea(when active: Bool) -> some View {
        modifier(GeoKitConditionalIgnoresSafeArea(active: active))
    }
}

private struct GeoKitConditionalIgnoresSafeArea: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.ignoresSafeArea()
        } else {
            content
        }
    }
}
