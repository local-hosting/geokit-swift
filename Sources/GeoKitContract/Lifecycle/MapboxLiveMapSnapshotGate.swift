import Foundation

/// Pure gate matching ``GeoKitMapboxLiveMapRegistry`` — testable without Mapbox UI.
public enum MapboxLiveMapSnapshotGate {
    public static func canStartSnapshotCapture(
        liveMapCount: Int,
        isWithinMetalTeardownGrace: Bool
    ) -> Bool {
        liveMapCount == 0 && !isWithinMetalTeardownGrace
    }
}
