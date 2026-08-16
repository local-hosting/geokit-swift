#if os(iOS) || os(visionOS)

import GeoKitUI
import MapboxMaps

extension GeoKitCalloutAnchor {
    init(_ anchor: ViewAnnotationAnchor) {
        switch anchor {
        case .topLeft: self = .topLeft
        case .top: self = .top
        case .topRight: self = .topRight
        case .bottomLeft: self = .bottomLeft
        case .bottom: self = .bottom
        case .bottomRight: self = .bottomRight
        case .left: self = .left
        case .right: self = .right
        default: self = .center
        }
    }

    var mapboxAnchor: ViewAnnotationAnchor {
        switch self {
        case .topLeft: return .topLeft
        case .top: return .top
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottom: return .bottom
        case .bottomRight: return .bottomRight
        case .left: return .left
        case .right: return .right
        case .center: return .center
        }
    }
}
#endif
