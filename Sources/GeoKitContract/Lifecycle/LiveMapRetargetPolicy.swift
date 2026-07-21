import Foundation

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

public enum LiveMapRetargetPolicy {
    public enum CardChangeAction: Equatable {
        case retargetCameraAndPins
        case reloadStyle
    }

    public static let sessionGlobalSurfaceIdentity = "geokit.session-global-live-map"

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

    public static func keepsLivePaintedOnRetarget(liveAlreadyPainted: Bool) -> Bool {
        liveAlreadyPainted
    }
}
