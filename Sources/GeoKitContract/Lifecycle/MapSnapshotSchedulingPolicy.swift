import Foundation

/// Pure peek-window index selection for map snapshot prefetch (provider-agnostic).
public enum MapSnapshotSchedulingPolicy {
    public static func peekIndices(
        centerIndex: Int,
        cardCount: Int,
        peekRadius: Int = GeoKitMapCardStageConstants.peekRadius,
        previousCenterIndex: Int? = nil
    ) -> [(index: Int, peekDistance: Int, force: Bool)] {
        guard cardCount > 0, peekRadius > 0 else { return [] }
        var results: [(Int, Int, Bool)] = []
        if let previousCenterIndex,
           previousCenterIndex != centerIndex,
           (0..<cardCount).contains(previousCenterIndex) {
            results.append((
                previousCenterIndex,
                abs(previousCenterIndex - centerIndex),
                true
            ))
        }
        for delta in (-peekRadius...peekRadius).sorted(by: { abs($0) < abs($1) }) {
            guard delta != 0 else { continue }
            let index = centerIndex + delta
            guard (0..<cardCount).contains(index) else { continue }
            results.append((index, abs(delta), false))
        }
        return results
    }
}
