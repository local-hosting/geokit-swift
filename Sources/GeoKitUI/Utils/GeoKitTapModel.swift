import CoreLocation
import MapboxMaps
import SwiftUI

struct GeoKitTap: Equatable, Identifiable {
    var id: UUID
    var coordinate: CLLocationCoordinate2D
    var color: Color = GeoKitMapTheme.accent
    var selected: Bool = false
    var selectedAnchor: ViewAnnotationAnchorConfig?
    var point: Point?
}
