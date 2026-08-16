import Foundation

/// Request fields that decide whether a live-map focus flip retargets or reloads the GL surface.
public struct LiveMapRequestIdentity: Equatable, Sendable {
    public var id: String
    public var mapStyleURI: String
    public var mapProviderId: MapProviderId?

    public init(id: String, mapStyleURI: String, mapProviderId: MapProviderId?) {
        self.id = id
        self.mapStyleURI = mapStyleURI
        self.mapProviderId = mapProviderId
    }

    public init(request: MapContentRequest) {
        self.init(
            id: request.id,
            mapStyleURI: request.mapStyleURI,
            mapProviderId: request.mapProviderId
        )
    }
}

/// Session-global live map: one Mapbox/MapKit surface, many cards as camera bookmarks.
public enum LiveMapRetargetPolicy {
    public enum CardChangeAction: Equatable {
        /// Jump camera, swap pins, keep the GL context.
        case retargetCameraAndPins
        /// Style or provider changed — surface must reload.
        case reloadStyle
    }

    /// Stable SwiftUI identity for the hoisted session-global surface — never the focused card id.
    public static let sessionGlobalSurfaceIdentity = "geokit.session-global-live-map"

    /// Focus flip on an already-mounted surface: same style/provider retargets; otherwise reload.
    public static func cardChangeAction(
        previous: LiveMapRequestIdentity?,
        next: LiveMapRequestIdentity
    ) -> CardChangeAction {
        guard let previous, previous.id != next.id else {
            return .retargetCameraAndPins
        }
        if previous.mapStyleURI != next.mapStyleURI {
            return .reloadStyle
        }
        if previous.mapProviderId != next.mapProviderId {
            return .reloadStyle
        }
        return .retargetCameraAndPins
    }

    /// Same-style retarget keeps the live surface painted — do not force a cold cover cycle.
    public static func keepsLivePaintedOnRetarget(liveAlreadyPainted: Bool) -> Bool {
        liveAlreadyPainted
    }
}
