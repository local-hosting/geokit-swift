import Foundation

enum GeoKitDemoConstants {
    static let mapStyleURI = "mapbox://styles/corio/cm1gmmsh900xd01nw38jtafz7"
}

enum GeoKitDemoLaunchArguments {
    static let uiTestMode = "-UITestMode"
    static let captureExpandFrames = "-CaptureExpandFrames"

    static var isUITestMode: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestMode)
    }
}
