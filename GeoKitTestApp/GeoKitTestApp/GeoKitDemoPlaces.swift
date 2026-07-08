import Foundation
import GeoKitContract

struct GeoKitDemoPlace: Identifiable, Sendable {
    let id: String
    let badge: String
    let title: String
    let latitude: Double
    let longitude: Double
    let preferredZoom: Double
    let pinHeading: String
    let pinSubheading: String
    let icon: String
    let extraPins: [GeoKitDemoExtraPin]

    struct GeoKitDemoExtraPin: Sendable {
        let id: UUID
        let latitude: Double
        let longitude: Double
        let pinHeading: String
        let pinSubheading: String
        let icon: String
    }

    var pins: [MapPin] {
        var all: [MapPin] = [
            MapPin(
                id: primaryPinID,
                latitude: latitude,
                longitude: longitude,
                pinHeading: pinHeading,
                pinSubheading: pinSubheading,
                icon: icon,
                isPrimary: true
            ),
        ]
        for extra in extraPins {
            all.append(
                MapPin(
                    id: extra.id,
                    latitude: extra.latitude,
                    longitude: extra.longitude,
                    pinHeading: extra.pinHeading,
                    pinSubheading: extra.pinSubheading,
                    icon: extra.icon,
                    isPrimary: false
                )
            )
        }
        return all
    }

    var defaultSelectedPinId: UUID { primaryPinID }

    var primaryPinID: UUID {
        UUID(uuidString: pinUUIDString) ?? UUID()
    }

    private var pinUUIDString: String {
        switch id {
        case "nyc-map": "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1"
        case "louisville-map": "B2B2B2B2-B2B2-B2B2-B2B2-B2B2B2B2B2B2"
        case "chicago-map": "C3C3C3C3-C3C3-C3C3-C3C3-C3C3C3C3C3C3"
        case "austin-map": "D4D4D4D4-D4D4-D4D4-D4D4-D4D4D4D4D4D4"
        case "seattle-map": "E5E5E5E5-E5E5-E5E5-E5E5-E5E5E5E5E5E5"
        case "miami-map": "F6F6F6F6-F6F6-F6F6-F6F6-F6F6F6F6F6F6"
        default: "00000000-0000-0000-0000-000000000001"
        }
    }
}

enum GeoKitDemoPlaces {
    private static let brooklynPinID = UUID(uuidString: "A2A2A2A2-A2A2-A2A2-A2A2-A2A2A2A2A2A2")!

    static let all: [GeoKitDemoPlace] = [
        GeoKitDemoPlace(
            id: "nyc-map", badge: "New York", title: "New York City",
            latitude: 40.7128, longitude: -74.0060, preferredZoom: 11,
            pinHeading: "City Hall", pinSubheading: "NYC", icon: "building.2",
            extraPins: [
                .init(id: brooklynPinID, latitude: 40.6782, longitude: -73.9442,
                      pinHeading: "Brooklyn Bridge", pinSubheading: "Brooklyn", icon: "bridge.fill")
            ]
        ),
        GeoKitDemoPlace(id: "louisville-map", badge: "Louisville", title: "Louisville", latitude: 38.2527, longitude: -85.7585, preferredZoom: 12, pinHeading: "Waterfront Park", pinSubheading: "KY", icon: "leaf.fill", extraPins: []),
        GeoKitDemoPlace(id: "chicago-map", badge: "Chicago", title: "Chicago", latitude: 41.8781, longitude: -87.6298, preferredZoom: 11, pinHeading: "Millennium Park", pinSubheading: "IL", icon: "building.columns.fill", extraPins: []),
        GeoKitDemoPlace(id: "austin-map", badge: "Austin", title: "Austin", latitude: 30.2672, longitude: -97.7431, preferredZoom: 12, pinHeading: "Capitol", pinSubheading: "TX", icon: "flag.fill", extraPins: []),
        GeoKitDemoPlace(id: "seattle-map", badge: "Seattle", title: "Seattle", latitude: 47.6062, longitude: -122.3321, preferredZoom: 11, pinHeading: "Pike Place", pinSubheading: "WA", icon: "fish.fill", extraPins: []),
        GeoKitDemoPlace(id: "miami-map", badge: "Miami", title: "Miami", latitude: 25.7617, longitude: -80.1918, preferredZoom: 12, pinHeading: "Bayfront Park", pinSubheading: "FL", icon: "sun.max.fill", extraPins: []),
    ]
}
