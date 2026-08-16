#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

import GeoKitContract
import SwiftUI

@MainActor
public enum GeoKitAppleProviderRegistration {
    private static var didRegister = false

    public static func activate() {
        guard !didRegister else { return }
        didRegister = true
        GeoKitMapProviderContentRegistry.register(.apple) { request in
            AnyView(GeoKitMapKitMapContent(request: request))
        }
        GeoKitSnapshotCaptureRegistry.register(.apple) { request, size, _ in
            await GeoKitCardSnapshotCapture.captureApple(request: request, size: size)
        }
    }

    public static func resetForTesting() {
        didRegister = false
    }
}
#endif
