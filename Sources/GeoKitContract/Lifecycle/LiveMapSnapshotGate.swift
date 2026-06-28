import Foundation

/// Pure gate for live-map / snapshot coordination — testable without map vendor UI.
public enum LiveMapSnapshotGate {
    public static func canStartSnapshotCapture(
        liveMapCount: Int,
        isWithinMetalTeardownGrace: Bool
    ) -> Bool {
        liveMapCount == 0 && !isWithinMetalTeardownGrace
    }
}
