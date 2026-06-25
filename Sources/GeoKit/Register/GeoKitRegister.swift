import Foundation
import GeoKitContract
import GeoKitUI

#if canImport(SwiftUI)
import SwiftUI
#endif

public enum GeoKitRegister {
    public static let version = "0.1.0"
    private static var didPrepareMapbox = false

    @MainActor
    public static func registerMapContent() {
        prepareMapboxIfNeeded()
        #if canImport(SwiftUI)
        GeoKitRuntime.mapContent = { request in
            AnyView(GeoKitMapContent(request: request))
        }
        fputs("[GeoKitRegister] mapContent registered\n", stderr)
        #endif
    }

    @MainActor
    private static func prepareMapboxIfNeeded() {
        guard !didPrepareMapbox else { return }
        didPrepareMapbox = true
        fputs("[GeoKitRegister] prepareMapbox — Mapbox loads inside GeoKit.framework\n", stderr)
        GeoKitMapBootstrap.prepareMapbox()
    }
}

@_cdecl("GeoKitRegister")
public func GeoKitRegisterEntryPoint() {
    if Thread.isMainThread {
        MainActor.assumeIsolated {
            GeoKitRegister.registerMapContent()
        }
    } else {
        DispatchQueue.main.sync {
            GeoKitRegister.registerMapContent()
        }
    }
}
