import Foundation
import GeoKitContract

#if canImport(SwiftUI)
import SwiftUI
#endif

public enum GeoKitRegister {
    public static let version = "0.1.0"

    @MainActor
    public static func registerMapContent() {
        #if canImport(SwiftUI)
        GeoKitRuntime.mapContent = { request in
            AnyView(GeoKitPlaceholderContent(request: request))
        }
        #endif
    }
}

#if canImport(SwiftUI)
private struct GeoKitPlaceholderContent: View {
    let request: MapContentRequest

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.11)
            VStack(spacing: 8) {
                Text("GeoKit")
                    .font(.headline)
                Text(request.phase.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("geokit-placeholder-\(request.cardID)")
    }
}
#endif
