import GeoKitContract
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Hosts may read this preference to skip rasterization (e.g. `drawingGroup`) while a live Mapbox surface is mounted.
public struct GeoKitLiveRenderingKey: PreferenceKey {
    public static var defaultValue = false

    public static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// When true, the map has visible raster content (snapshot or live frame) for the host to observe.
public struct GeoKitMapRenderedKey: PreferenceKey {
    public static var defaultValue = false

    public static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// When true, the map owns pan/zoom gestures; host chrome should defer competing drag handlers.
public struct GeoKitMapInteractiveGesturesKey: PreferenceKey {
    public static var defaultValue = false

    public static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// Latest selected pin id from a live map surface — hosts may persist across remounts.
public struct GeoKitSelectedPinIdKey: PreferenceKey {
    public static var defaultValue: UUID? = nil

    public static func reduce(value: inout UUID?, nextValue: () -> UUID?) {
        if let next = nextValue() {
            value = next
        }
    }
}

/// When true, the card slot should keep its peek snapshot (baked pins) over painted live map tiles.
public struct GeoKitMapSnapshotCoversLiveKey: PreferenceKey {
    public static var defaultValue = false

    public static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// Latest provider-neutral camera frame from a live map surface — hosts may persist across provider switches.
public struct GeoKitMapCameraFrameKey: PreferenceKey {
    public static var defaultValue: MapCameraFrame? = nil

    public static func reduce(value: inout MapCameraFrame?, nextValue: () -> MapCameraFrame?) {
        if let next = nextValue() {
            value = next
        }
    }
}

private struct GeoKitMapSurfaceReadyKey: EnvironmentKey {
    static let defaultValue = true
}

private struct GeoKitMapIsTransitioningKey: EnvironmentKey {
    static let defaultValue = false
}

private struct GeoKitCardTransitionBaseSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

private struct GeoKitCardTransitionTargetSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

private struct GeoKitCardTransitionFullTargetSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

#if os(iOS)
private struct GeoKitTransitionSnapshotKey: EnvironmentKey {
    static let defaultValue: UIImage? = nil
}
#endif

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

    /// Collapsed card size when expand/collapse spring begins — drives snapshot vertical reveal.
    var geokitCardTransitionBaseSize: CGSize {
        get { self[GeoKitCardTransitionBaseSizeKey.self] }
        set { self[GeoKitCardTransitionBaseSizeKey.self] = newValue }
    }

    /// Current spring target card size — pair with ``geokitCardTransitionBaseSize``.
    var geokitCardTransitionTargetSize: CGSize {
        get { self[GeoKitCardTransitionTargetSizeKey.self] }
        set { self[GeoKitCardTransitionTargetSizeKey.self] = newValue }
    }

    /// Final expanded card size for the active spring — snapshot source height uses this, not the in-flight target.
    var geokitCardTransitionFullTargetSize: CGSize {
        get { self[GeoKitCardTransitionFullTargetSizeKey.self] }
        set { self[GeoKitCardTransitionFullTargetSizeKey.self] = newValue }
    }

#if os(iOS)
    /// Host-owned static snapshot (e.g. card fan capture) for live-map crossfade on expand/remount.
    var geokitTransitionSnapshot: UIImage? {
        get { self[GeoKitTransitionSnapshotKey.self] }
        set { self[GeoKitTransitionSnapshotKey.self] = newValue }
    }
#endif
}

extension View {
    public func geokitIgnoresSafeArea(when active: Bool) -> some View {
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
