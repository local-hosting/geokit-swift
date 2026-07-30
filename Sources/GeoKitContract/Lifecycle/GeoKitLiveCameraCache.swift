import Foundation

/// Synchronous last-known live camera per map id.
///
/// Mapbox `onCameraChanged` and preference delivery are deferred onto the next main turn so they
/// stay out of SwiftUI view updates. Collapse can start on the same turn as the last pan — before
/// those deferred writes land in ``MapCameraStore``. This cache is updated immediately from the
/// live surface so collapse capture / park decisions can read the camera the user is actually seeing.
@MainActor
public enum GeoKitLiveCameraCache {
    private static var frames: [String: MapCameraFrame] = [:]

    public static func note(_ frame: MapCameraFrame, for mapID: String) {
        if let existing = frames[mapID], existing.isApproximatelyEqual(to: frame) {
            return
        }
        frames[mapID] = frame
    }

    public static func frame(for mapID: String) -> MapCameraFrame? {
        frames[mapID]
    }

    /// Copies the cached live frame into `store` when present. Returns the frame that was applied.
    @discardableResult
    public static func flush(into store: GeoKitLiveCameraStoreWriting, mapID: String) -> MapCameraFrame? {
        guard let frame = frames[mapID] else { return nil }
        store.setLiveCameraFrame(frame, for: mapID)
        return frame
    }

    public static func remove(for mapID: String) {
        frames.removeValue(forKey: mapID)
    }

    public static func removeAll() {
        frames.removeAll()
    }
}

/// Narrow write surface so contract code can flush into ``MapCameraStore`` without importing GeoKitUI.
@MainActor
public protocol GeoKitLiveCameraStoreWriting: AnyObject {
    func setLiveCameraFrame(_ frame: MapCameraFrame, for mapID: String)
}
