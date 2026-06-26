import Foundation
import GeoKitContract

/// Per-map camera persistence — one shared frame per card across Mapbox and MapKit.
@MainActor
public final class MapCameraStore: ObservableObject {
    private let defaults: UserDefaults
    private let keyPrefix: String
    private var cache: [String: MapCameraFrame] = [:]
    private var persistTask: Task<Void, Never>?
    private var dirtyIDs: Set<String> = []

    public init(defaults: UserDefaults = .standard, keyPrefix: String = "geokit.map.camera.") {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    public func frame(for mapID: String) -> MapCameraFrame? {
        if let cached = cache[mapID] { return cached }
        guard let data = defaults.data(forKey: storageKey(mapID)),
              let frame = try? JSONDecoder().decode(MapCameraFrame.self, from: data)
        else { return nil }
        cache[mapID] = frame
        return frame
    }

    public func setFrame(_ cameraFrame: MapCameraFrame, for mapID: String) {
        if let existing = frame(for: mapID), existing.isApproximatelyEqual(to: cameraFrame) {
            return
        }
        cache[mapID] = cameraFrame
        dirtyIDs.insert(mapID)
        schedulePersist()
    }

    public func removeFrame(for mapID: String) {
        cache.removeValue(forKey: mapID)
        dirtyIDs.remove(mapID)
        defaults.removeObject(forKey: storageKey(mapID))
    }

    public func removeAll() {
        for mapID in cache.keys {
            defaults.removeObject(forKey: storageKey(mapID))
        }
        cache.removeAll()
        dirtyIDs.removeAll()
        persistTask?.cancel()
        persistTask = nil
    }

    private func storageKey(_ mapID: String) -> String { keyPrefix + mapID }

    private func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self else { return }
            self.flushDirtyFrames()
        }
    }

    private func flushDirtyFrames() {
        let ids = dirtyIDs
        dirtyIDs.removeAll()
        let encoder = JSONEncoder()
        for mapID in ids {
            guard let frame = cache[mapID],
                  let data = try? encoder.encode(frame) else { continue }
            defaults.set(data, forKey: storageKey(mapID))
        }
    }
}
