import Foundation
import GeoKitContract

/// Session-scoped live camera frames keyed by map card id.
///
/// Preference updates land here synchronously so collapse handoff and snapshot capture
/// can read the latest pan before ``MapCameraStore`` persistence catches up.
@MainActor
public enum GeoKitLiveCameraCache {
    private static var frames: [String: MapCameraFrame] = [:]

    public static func note(_ frame: MapCameraFrame, for mapID: String) {
        frames[mapID] = frame
    }

    public static func frame(for mapID: String) -> MapCameraFrame? {
        frames[mapID]
    }

    public static func flush(into store: MapCameraStore, mapID: String) {
        guard let frame = frames[mapID] else { return }
        store.setFrame(frame, for: mapID)
    }

    public static func remove(for mapID: String) {
        frames.removeValue(forKey: mapID)
    }
}
