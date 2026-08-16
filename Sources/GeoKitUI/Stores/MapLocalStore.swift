import Foundation
import GeoKitContract

/// Durable per-`mapId` camera + pin selection (Tier B local state).
@MainActor
public final class MapLocalStore {
    public static let shared = MapLocalStore()

    private let defaults: UserDefaults
    private let keyPrefix: String
    private var memory: [String: MapLocalState] = [:]

    public init(defaults: UserDefaults = .standard, keyPrefix: String = "geokit.map.local.v1.") {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    public func state(
        for mapID: String,
        scope: MapLocalPersistScope = MapOfflineDefaults.durablePersistScope
    ) -> MapLocalState? {
        if scope == .memory {
            return memory[mapID]
        }
        if let cached = memory[mapID] {
            return cached
        }
        guard let data = defaults.data(forKey: storageKey(mapID)),
              let decoded = try? JSONDecoder().decode(MapLocalState.self, from: data)
        else { return nil }
        memory[mapID] = decoded
        return decoded
    }

    public func setState(_ state: MapLocalState) {
        var next = state
        next.updatedAt = Date()
        memory[next.mapId] = next
        guard next.persistScope != .memory else { return }
        guard let data = try? JSONEncoder().encode(next) else { return }
        defaults.set(data, forKey: storageKey(next.mapId))
    }

    public func patch(
        mapID: String,
        cameraFrame: MapCameraFrame? = nil,
        selectedPinId: UUID?? = nil,
        scope: MapLocalPersistScope = MapOfflineDefaults.durablePersistScope
    ) {
        var existing = state(for: mapID, scope: scope)
            ?? MapLocalState(mapId: mapID, persistScope: scope)
        if let cameraFrame {
            existing.cameraFrame = cameraFrame
        }
        if let selectedPinId {
            existing.selectedPinId = selectedPinId
        }
        existing.persistScope = scope
        setState(existing)
    }

    public func removeState(for mapID: String) {
        memory.removeValue(forKey: mapID)
        defaults.removeObject(forKey: storageKey(mapID))
    }

    public func removeAll() {
        for mapID in memory.keys {
            defaults.removeObject(forKey: storageKey(mapID))
        }
        memory.removeAll()
    }

    public static func resetForTesting() {
        shared.removeAll()
    }

    private func storageKey(_ mapID: String) -> String { keyPrefix + mapID }
}
