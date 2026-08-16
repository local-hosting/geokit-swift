#if os(iOS) || os(visionOS)

@_spi(Restricted) import MapboxMaps
import GeoKitUI
import SwiftUI

enum GeoKitMapTokens {
    static func liveOrnamentOptions(interactiveGestures: Bool) -> OrnamentOptions {
        var logo = LogoViewOptions(position: .bottomLeft)
        logo.visibility = .hidden
        var attribution = AttributionButtonOptions()
        attribution.visibility = .hidden
        return OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(
                position: .bottomLeft,
                margins: CGPoint(x: 20, y: 20),
                visibility: .hidden
            ),
            logo: logo,
            attributionButton: attribution
        )
    }

    static func snapshotOptions(size: CGSize, pixelRatio: CGFloat) -> MapSnapshotOptions {
        MapSnapshotOptions(
            size: size,
            pixelRatio: pixelRatio,
            showsLogo: false,
            showsAttribution: false
        )
    }
}
#endif
