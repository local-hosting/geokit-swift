import Foundation

/// Mapbox-free pin payload passed from the host into GeoKit map content.
public struct MapPin: Sendable, Equatable, Identifiable {
    public var id: UUID
    public var latitude: Double
    public var longitude: Double
    public var pinHeading: String
    public var pinSubheading: String
    public var icon: String
    public var isPrimary: Bool

    public init(
        id: UUID,
        latitude: Double,
        longitude: Double,
        pinHeading: String,
        pinSubheading: String,
        icon: String,
        isPrimary: Bool
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.pinHeading = pinHeading
        self.pinSubheading = pinSubheading
        self.icon = icon
        self.isPrimary = isPrimary
    }
}
