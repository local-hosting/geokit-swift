#if os(iOS) || os(visionOS)

import GeoKitContract
import GeoKitUI
import MapboxCommon
import SwiftUI

@MainActor
enum GeoKitMapboxBootstrap {
    private static var didRegister = false

    static func activate() {
        guard !didRegister else { return }
        didRegister = true
        GeoKitMapProviderBootstrapRegistry.register(.mapbox) {
            GeoKitMapboxBootstrap.prepareMapbox()
        }
        GeoKitMapProviderContentRegistry.register(.mapbox) { request in
            AnyView(GeoKitMapboxMapContent(request: request))
        }
        GeoKitSnapshotCaptureRegistry.register(.mapbox) { request, size, priority in
            try await GeoKitCardSnapshotCaptureMapbox.capture(
                request: request,
                size: size,
                priority: priority
            )
        }
        LiveMapSnapshotCoordinator.canStartSnapshotCapture = {
            GeoKitMapboxLiveMapRegistry.canStartSnapshotCapture
        }
        GeoKitRuntime.prefetchOfflineRegionOnContextLoad = { prefetchRequest, contentRequest in
            guard let styleURI = StyleURI(rawValue: contentRequest.mapStyleURI) else { return }
            _ = GeoKitMapboxOfflineRegionStore.shared.prefetch(
                request: prefetchRequest,
                styleURI: styleURI,
                policy: contentRequest.offlineContext?.policy ?? .cacheFirst
            )
        }
        LiveMapSnapshotCoordinator.waitUntilSafeForSnapshot = {
            try await GeoKitMapboxLiveMapRegistry.waitUntilSafeForSnapshot()
        }
    }

    static func prepareMapbox() {
        if MapboxOptions.accessToken.isEmpty,
           let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String,
           !token.isEmpty {
            MapboxOptions.accessToken = token
        }
        _ = GeoKitMapboxConfiguration.telemetryOptOut
        _ = GeoKitMapboxLogging.configureOnce
    }

    static func resetForTesting() {
        didRegister = false
        GeoKitRuntime.prefetchOfflineRegionOnContextLoad = nil
    }
}

private enum GeoKitMapboxConfiguration {
    static let telemetryOptOut: Void = {
        UserDefaults.standard.register(defaults: ["MGLMapboxMetricsEnabled": false])
        UserDefaults.standard.set(false, forKey: "MGLMapboxMetricsEnabled")
    }()
}

private enum GeoKitMapboxLogging {
    static let configureOnce: Void = {
        LogConfiguration.setLoggingLevelForUpTo(nil)
    }()
}
#endif
