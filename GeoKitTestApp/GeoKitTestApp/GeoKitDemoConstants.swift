import Foundation

/// Demo Mapbox style URI — override via host app config in production.
enum GeoKitDemoConstants {
    /// Global Accord animation speed (`AX.Animation.speed`). `2/3` ≈ 1.5× slower motion.
    static let animationSpeed: Double = 2.0 / 3.0

    /// Peek tiles and expand/collapse snapshots — demo Mapbox style.
    static let snapshotMapStyleURI = "mapbox://styles/mapbox/streets-v12"

    /// Live GPU map — same style as snapshots so crossfade is seamless.
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
