import Foundation
import GeoKitContract
import GeoKitUI
import GeoKitUIMapbox

#if canImport(SwiftUI)
import SwiftUI
#endif

public enum GeoKitRegister {
    public static let version = "0.1.0"
    private static var didPrepareProvider = false

    @MainActor
    public static func registerMapContent() {
        #if os(iOS)
        GeoKitUIRegistration.activate()
        GeoKitUIMapboxRegistration.activate()
        #endif
        prepareProviderIfNeeded()
        #if os(iOS)
        GeoKitRuntime.mapContent = { request in
            AnyView(GeoKitMapContent(request: request))
        }
        fputs("[GeoKitRegister] mapContent registered\n", stderr)
        #endif
    }

    @MainActor
    private static func prepareProviderIfNeeded() {
        guard !didPrepareProvider else { return }
        didPrepareProvider = true
        let provider = GeoKitMapProviderRegistry.defaultProvider
        fputs("[GeoKitRegister] prepare provider=\(provider.rawValue)\n", stderr)
        #if os(iOS)
        GeoKitMapBootstrap.prepare(provider: provider)
        #endif
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
