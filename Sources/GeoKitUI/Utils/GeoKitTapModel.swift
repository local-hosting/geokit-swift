import CoreLocation
import SwiftUI

public struct GeoKitTap: Equatable, Identifiable {
    public var id: UUID
    public var coordinate: CLLocationCoordinate2D
    public var color: Color
    public var selected: Bool
    public var selectedAnchor: GeoKitCalloutAnchor?

    public init(
        id: UUID,
        coordinate: CLLocationCoordinate2D,
        color: Color = Color(red: 69 / 255, green: 56 / 255, blue: 178 / 255),
        selected: Bool = false,
        selectedAnchor: GeoKitCalloutAnchor? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.color = color
        self.selected = selected
        self.selectedAnchor = selectedAnchor
    }
}

extension GeoKitTap {
    public static func == (lhs: GeoKitTap, rhs: GeoKitTap) -> Bool {
        lhs.id == rhs.id
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.color == rhs.color
            && lhs.selected == rhs.selected
            && lhs.selectedAnchor == rhs.selectedAnchor
    }
}
