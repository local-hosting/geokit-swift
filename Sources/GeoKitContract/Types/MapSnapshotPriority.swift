import Foundation

/// Snapshot capture priority — the front card should preempt background peek captures.
public enum MapSnapshotPriority: Int, Sendable, Equatable, Comparable {
    case background = 0
    case top = 1

    public static func < (lhs: MapSnapshotPriority, rhs: MapSnapshotPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
