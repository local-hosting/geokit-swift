#if os(iOS) || os(visionOS)

import Foundation
import GeoKitContract
import GeoKitUI

/// Tracks live Mapbox surfaces so ``Snapshotter`` never runs concurrently with Metal map views.
@MainActor
public enum GeoKitMapboxLiveMapRegistry {
    private static var liveMapCount = 0
    private static var lastLiveMapUnregisterTime: Date?
    private static var safeForSnapshotHandlers: [UUID: @MainActor () -> Void] = [:]
    private static var safeNotificationTask: Task<Void, Never>?

    public static let metalTeardownGrace: TimeInterval = 0.35
    private static let maxWait: TimeInterval = 8

    public static var hasActiveLiveMap: Bool { liveMapCount > 0 }

    private static var isWithinMetalTeardownGrace: Bool {
        guard liveMapCount == 0, let last = lastLiveMapUnregisterTime else { return false }
        return Date().timeIntervalSince(last) < metalTeardownGrace
    }

    public static var canStartSnapshotCapture: Bool {
        LiveMapSnapshotGate.canStartSnapshotCapture(
            liveMapCount: liveMapCount,
            isWithinMetalTeardownGrace: isWithinMetalTeardownGrace
        )
    }

    public static func resetForTesting() {
        liveMapCount = 0
        lastLiveMapUnregisterTime = nil
        safeForSnapshotHandlers.removeAll()
        safeNotificationTask?.cancel()
        safeNotificationTask = nil
    }

    public static func registerLiveMap() {
        liveMapCount += 1
    }

    public static func unregisterLiveMap() {
        liveMapCount = max(0, liveMapCount - 1)
        if liveMapCount == 0 {
            lastLiveMapUnregisterTime = Date()
            scheduleSafeForSnapshotNotification()
        }
    }

    @discardableResult
    public static func onSafeForSnapshot(_ handler: @escaping @MainActor () -> Void) -> UUID {
        let id = UUID()
        safeForSnapshotHandlers[id] = handler
        if canStartSnapshotCapture {
            scheduleSafeForSnapshotNotification()
        }
        return id
    }

    public static func removeSafeForSnapshotHandler(_ id: UUID) {
        safeForSnapshotHandlers.removeValue(forKey: id)
    }

    private static func scheduleSafeForSnapshotNotification() {
        safeNotificationTask?.cancel()
        safeNotificationTask = Task { @MainActor in
            let graceMs = Int(metalTeardownGrace * 1000) + 50
            try? await Task.sleep(for: .milliseconds(graceMs))
            guard !Task.isCancelled, canStartSnapshotCapture else { return }
            notifySafeForSnapshotHandlers()
        }
    }

    /// Drain pending handlers before invoking so overlapping notification tasks cannot double-fire one handler.
    private static func notifySafeForSnapshotHandlers() {
        guard !safeForSnapshotHandlers.isEmpty else { return }
        let handlers = Array(safeForSnapshotHandlers.values)
        safeForSnapshotHandlers.removeAll()
        for handler in handlers {
            handler()
        }
    }

    public static func waitUntilSafeForSnapshot() async throws {
        let deadline = Date().addingTimeInterval(maxWait)
        while !canStartSnapshotCapture {
            if Task.isCancelled { throw CancellationError() }
            if Date() > deadline {
                throw GeoKitMapboxSurfaceCoordinationError.snapshotBlocked
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        let graceMs = Int(metalTeardownGrace * 1000)
        try await Task.sleep(for: .milliseconds(graceMs))
        if !canStartSnapshotCapture {
            throw GeoKitMapboxSurfaceCoordinationError.snapshotBlocked
        }
    }
}

public enum GeoKitMapboxSurfaceCoordinationError: Error {
    case snapshotBlocked
}
#endif
