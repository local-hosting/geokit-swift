import GeoKit
import GeoKitContract
import GeoKitUI
import SwiftUI

@main
struct GeoKitTestAppApp: App {
    init() {
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
