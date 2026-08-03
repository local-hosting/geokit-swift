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
        geoKitLog("mapContent registered")
        #elseif os(macOS)
        GeoKitUIRegistration.activate()
        GeoKitRuntime.mapContent = { request in
            AnyView(GeoKitMapContent(request: request))
        }
        geoKitLog("mapContent registered (macOS)")
        #elseif canImport(SwiftUI)
        GeoKitRuntime.mapContent = { _ in
            AnyView(GeoKitUnavailableMapContent())
        }
        geoKitLog("mapContent placeholder registered")
        #endif
        prepareProviderIfNeeded()
    }

    @MainActor
    private static func prepareProviderIfNeeded() {
        guard !didPrepareProvider else { return }
        didPrepareProvider = true
        let provider = GeoKitMapProviderRegistry.defaultProvider
        geoKitLog("prepare provider=\(provider.rawValue)")
        #if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)
        GeoKitMapBootstrap.prepare(provider: provider)
        #endif
    }
}

private func geoKitLog(_ message: String) {
    guard ProcessInfo.processInfo.environment["CF_GEOKIT_DEBUG"] == "1" else { return }
    fputs("[GeoKitRegister] \(message)\n", stderr)
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
