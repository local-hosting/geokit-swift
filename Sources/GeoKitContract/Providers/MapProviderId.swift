import Foundation

/// Supported native map rendering backends for GeoKitUI.
public enum MapProviderId: String, Sendable, Equatable, CaseIterable {
    case mapbox
    case apple
}

public enum MapProviderConfigurationError: Error, Equatable, Sendable {
    case unknownProvider(String)
}

public enum MapProviderResolver {
    private static let providerKeys = ["GEOKIT_MAP_PROVIDER", "MAP_PROVIDER"]

    public static func normalizeHint(_ hint: String?) -> MapProviderId? {
        guard let trimmed = hint?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return try? parse(trimmed)
    }

    public static func parse(_ raw: String) throws -> MapProviderId {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "mapbox":
            return .mapbox
        case "apple", "mapkit", "apple-maps", "applemaps":
            return .apple
        default:
            throw MapProviderConfigurationError.unknownProvider(raw)
        }
    }

    public static func fromEnvironment(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoPlistValue: String? = Bundle.main.object(forInfoDictionaryKey: "GEOKIT_MAP_PROVIDER") as? String
    ) -> MapProviderId {
        for key in providerKeys {
            if let raw = environment[key], let provider = normalizeHint(raw) {
                return provider
            }
        }
        if let provider = normalizeHint(infoPlistValue) {
            return provider
        }
        return .mapbox
    }
}
