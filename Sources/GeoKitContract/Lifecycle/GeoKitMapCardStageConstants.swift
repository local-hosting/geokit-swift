import Foundation

/// Card-stack map staging constants — GeoKit owns peek windows and snapshot scheduling (not ``AX.Map``).
public enum GeoKitMapCardStageConstants {
    /// Cards within ±this index distance of center may receive peek snapshots.
    public static let peekRadius = 2
}
