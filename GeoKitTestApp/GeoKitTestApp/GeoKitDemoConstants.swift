import Foundation

/// Keep snapshot style in sync with `@corio-platforms/geokit/config/map-style` (`CORIO_MAPBOX_STYLE_URI`).
enum GeoKitDemoConstants {
    /// Peek tiles and expand/collapse snapshots — light Corio style.
    static let snapshotMapStyleURI = "mapbox://styles/corio/cm1gmmsh900xd01nw38jtafz7"

    #if DEBUG
    /// Live GPU map in debug builds — dark Mapbox style so live vs snapshot is obvious.
    static let liveMapStyleURI = "mapbox://styles/mapbox/dark-v11"
    #else
    static let liveMapStyleURI = snapshotMapStyleURI
    #endif

    /// Registry bootstrap default (snapshots + Mapbox init).
    static let mapStyleURI = snapshotMapStyleURI
}

enum GeoKitDemoLaunchArguments {
    static let uiTestMode = "-UITestMode"
    static let captureExpandFrames = "-CaptureExpandFrames"

    static var isUITestMode: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestMode)
    }
}
