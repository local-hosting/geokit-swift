import AccordDesignSystem
import GeoKit
import SwiftUI

@main
struct GeoKitTestAppApp: App {
    init() {
        AX.bootstrap()
        GeoKitRegister.registerMapContent()
    }

    var body: some Scene {
        WindowGroup {
            GeoKitDemoRootView()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
        }
    }
}
