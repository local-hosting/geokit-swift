import Foundation

/// Injectable live-map snapshot coordination — Mapbox registers Metal teardown rules via GeoKitUIMapbox.
@MainActor
public enum LiveMapSnapshotCoordinator {
    public static var canStartSnapshotCapture: @MainActor () -> Bool = { true }

    public static var waitUntilSafeForSnapshot: @MainActor () async throws -> Void = {}

    public static func resetForTesting() {
        canStartSnapshotCapture = { true }
        waitUntilSafeForSnapshot = {}
    }
}
