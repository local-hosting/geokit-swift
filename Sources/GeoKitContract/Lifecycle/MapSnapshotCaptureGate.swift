import Foundation

/// Provider-aware rules for when peek snapshot capture may run.
public enum MapSnapshotCaptureGate {
    /// Mapbox ``Snapshotter`` cannot run concurrently with a live Metal map; MapKit snapshots do not share this lock.
    public static func requiresLiveMapSafeWindow(for provider: MapProviderId) -> Bool {
        switch provider {
        case .mapbox:
            return true
        case .apple:
            return false
        }
    }

    public static func shouldDeferCapture(provider: MapProviderId, liveMapActive: Bool) -> Bool {
        requiresLiveMapSafeWindow(for: provider) && liveMapActive
    }
}
