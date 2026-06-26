import AccordDesignSystem
import GeoKit
import GeoKitContract
import GeoKitUI
import SwiftUI

@main
struct GeoKitTestAppApp: App {
    init() {
        AX.bootstrap()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-CaptureExpandFrames") {
            AX.Animation.speed = 0.1
        }
        #endif
        GeoKitMapProviderRegistry.configure(
            provider: .mapbox,
            mapbox: MapboxProviderConfig(styleURI: GeoKitDemoConstants.mapStyleURI)
        )
        GeoKitRegister.registerMapContent()
        GeoKitMapBootstrap.prepare(provider: .mapbox)
    }

    var body: some Scene {
        WindowGroup {
            GeoKitDemoRootView()
                .preferredColorScheme(.dark)
        }
    }
}
