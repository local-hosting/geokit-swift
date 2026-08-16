// Registers live map content on iOS (incl. CarPlay), visionOS (MapKit + Mapbox), tvOS (MapKit only), and macOS (MapKit only).
// Platform matrix: geokit-swift/docs/platforms.md
import Foundation
import GeoKitContract
import GeoKitUI
#if os(iOS) || os(visionOS)
import GeoKitUIMapbox
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

public enum GeoKitRegister {
    public static let version = "0.1.0"
    private static var didPrepareProvider = false

    @MainActor
    public static func registerMapContent() {
        #if os(iOS) || os(visionOS) || os(tvOS)
        GeoKitUIRegistration.activate()
        #if os(iOS) || os(visionOS)
        GeoKitUIMapboxRegistration.activate()
        #endif
        GeoKitRuntime.mapContent = { request in
            AnyView(GeoKitMapContent(request: request))
        }
        fputs("[GeoKitRegister] mapContent registered\n", stderr)
        #elseif os(macOS)
        GeoKitUIRegistration.activate()
        GeoKitRuntime.mapContent = { request in
            AnyView(GeoKitMapContent(request: request))
        }
        fputs("[GeoKitRegister] mapContent registered (macOS)\n", stderr)
        #elseif canImport(SwiftUI)
        GeoKitRuntime.mapContent = { _ in
            AnyView(GeoKitUnavailableMapContent())
        }
        fputs("[GeoKitRegister] mapContent placeholder registered\n", stderr)
        #endif
        prepareProviderIfNeeded()
    }

    @MainActor
    private static func prepareProviderIfNeeded() {
        guard !didPrepareProvider else { return }
        didPrepareProvider = true
        let provider = GeoKitMapProviderRegistry.defaultProvider
        fputs("[GeoKitRegister] prepare provider=\(provider.rawValue)\n", stderr)
        #if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)
        GeoKitMapBootstrap.prepare(provider: provider)
        #endif
    }
}

#if canImport(SwiftUI) && !os(iOS) && !os(visionOS) && !os(tvOS) && !os(macOS)
private struct GeoKitUnavailableMapContent: View {
    var body: some View {
        Color.clear
            .accessibilityLabel("Map unavailable on this platform")
    }
}
#endif

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
