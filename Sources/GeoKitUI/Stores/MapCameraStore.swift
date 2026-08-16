import Foundation
import GeoKitContract

/// Per-map camera persistence — one shared frame per card across Mapbox and MapKit.
@MainActor
public final class MapCameraStore: ObservableObject {
    private let localStore: MapLocalStore
    private let defaults: UserDefaults
    private let legacyKeyPrefix: String
    private var cache: [String: MapCameraFrame] = [:]
    private var persistTask: Task<Void, Never>?
    private var dirtyIDs: Set<String> = []

    public init(
        localStore: MapLocalStore = .shared,
        defaults: UserDefaults = .standard,
        keyPrefix: String = "geokit.map.camera."
    ) {
        self.localStore = localStore
        self.defaults = defaults
        self.legacyKeyPrefix = keyPrefix
    }

    public func frame(for mapID: String) -> MapCameraFrame? {
        if let cached = cache[mapID] { return cached }
        if let camera = localStore.state(for: mapID)?.cameraFrame {
            cache[mapID] = camera
            return camera
        }
        guard let data = defaults.data(forKey: legacyStorageKey(mapID)),
              let frame = try? JSONDecoder().decode(MapCameraFrame.self, from: data)
        else { return nil }
        cache[mapID] = frame
        localStore.patch(mapID: mapID, cameraFrame: frame)
        defaults.removeObject(forKey: legacyStorageKey(mapID))
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
        defaults.removeObject(forKey: legacyStorageKey(mapID))
        var state = localStore.state(for: mapID) ?? MapLocalState(mapId: mapID)
        state.cameraFrame = nil
        localStore.setState(state)
    }

    public func removeAll() {
        for mapID in cache.keys {
            defaults.removeObject(forKey: legacyStorageKey(mapID))
        }
        cache.removeAll()
        dirtyIDs.removeAll()
        persistTask?.cancel()
        persistTask = nil
        localStore.removeAll()
    }

    private func legacyStorageKey(_ mapID: String) -> String { legacyKeyPrefix + mapID }

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
        for mapID in ids {
            guard let frame = cache[mapID] else { continue }
            localStore.patch(mapID: mapID, cameraFrame: frame)
        }
    }
}

extension MapCameraStore: GeoKitLiveCameraStoreWriting {
    public func setLiveCameraFrame(_ frame: MapCameraFrame, for mapID: String) {
        setFrame(frame, for: mapID)
    }
}
