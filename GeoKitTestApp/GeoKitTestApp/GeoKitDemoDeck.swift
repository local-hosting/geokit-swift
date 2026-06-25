import Foundation
import AccordDesignSystem
import GeoKitContract

@MainActor
final class GeoKitDemoDeck: AXCardCollectionModel<GeoKitDemoCard> {
    override init() {
        super.init()
        cards = Self.sampleCards
    }

    private static let sampleCards: [GeoKitDemoCard] = [
        GeoKitDemoCard(
            id: "nyc",
            title: "New York",
            subtitle: "Manhattan demo pin",
            pins: [
                MapPin(
                    id: UUID(uuidString: "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1")!,
                    latitude: 40.7128,
                    longitude: -74.006,
                    pinHeading: "City Hall",
                    pinSubheading: "NYC",
                    icon: "building.2",
                    isPrimary: false
                ),
            ]
        ),
        GeoKitDemoCard(
            id: "louisville",
            title: "Louisville",
            subtitle: "Corio demo market",
            pins: [
                MapPin(
                    id: UUID(uuidString: "B2B2B2B2-B2B2-B2B2-B2B2-B2B2B2B2B2B2")!,
                    latitude: 38.2527,
                    longitude: -85.7585,
                    pinHeading: "Downtown",
                    pinSubheading: "Louisville, KY",
                    icon: "mappin.circle",
                    isPrimary: true
                ),
            ]
        ),
        GeoKitDemoCard(
            id: "san-francisco",
            title: "San Francisco",
            subtitle: "Bay Area demo",
            pins: [
                MapPin(
                    id: UUID(uuidString: "C3C3C3C3-C3C3-C3C3-C3C3-C3C3C3C3C3C3")!,
                    latitude: 37.7749,
                    longitude: -122.4194,
                    pinHeading: "Union Square",
                    pinSubheading: "San Francisco, CA",
                    icon: "tram.fill",
                    isPrimary: true
                ),
            ]
        ),
        GeoKitDemoCard(
            id: "chicago",
            title: "Chicago",
            subtitle: "Loop demo pin",
            pins: [
                MapPin(
                    id: UUID(uuidString: "D4D4D4D4-D4D4-D4D4-D4D4-D4D4D4D4D4D4")!,
                    latitude: 41.8781,
                    longitude: -87.6298,
                    pinHeading: "The Loop",
                    pinSubheading: "Chicago, IL",
                    icon: "building.columns",
                    isPrimary: false
                ),
            ]
        ),
        GeoKitDemoCard(
            id: "austin",
            title: "Austin",
            subtitle: "Texas demo market",
            pins: [
                MapPin(
                    id: UUID(uuidString: "E5E5E5E5-E5E5-E5E5-E5E5-E5E5E5E5E5E5")!,
                    latitude: 30.2672,
                    longitude: -97.7431,
                    pinHeading: "State Capitol",
                    pinSubheading: "Austin, TX",
                    icon: "music.note",
                    isPrimary: true
                ),
            ]
        ),
        GeoKitDemoCard(
            id: "denver",
            title: "Denver",
            subtitle: "Front Range demo",
            pins: [
                MapPin(
                    id: UUID(uuidString: "F6F6F6F6-F6F6-F6F6-F6F6-F6F6F6F6F6F6")!,
                    latitude: 39.7392,
                    longitude: -104.9903,
                    pinHeading: "Civic Center",
                    pinSubheading: "Denver, CO",
                    icon: "mountain.2",
                    isPrimary: false
                ),
            ]
        ),
    ]
}
