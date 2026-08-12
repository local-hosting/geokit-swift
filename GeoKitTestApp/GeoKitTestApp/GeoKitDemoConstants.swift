import Foundation

/// Keep snapshot style in sync with `@corio-platforms/geokit/config/map-style` (`CORIO_MAPBOX_STYLE_URI`).
enum GeoKitDemoConstants {
    /// Global Corio animation speed (`CX.Animation.speed`). `2/3` ≈ 1.5× slower motion.
    static let animationSpeed: Double = 2.0 / 3.0

    /// Peek tiles and expand/collapse snapshots — light Corio style.
    static let snapshotMapStyleURI = "mapbox://styles/corio/cm1gmmsh900xd01nw38jtafz7"

    /// Live GPU map — same Corio style as snapshots so crossfade is seamless.
    static let liveMapStyleURI = snapshotMapStyleURI

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
