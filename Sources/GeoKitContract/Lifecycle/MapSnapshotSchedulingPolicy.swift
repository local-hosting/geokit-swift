import CardMediaContract
import Foundation

/// Pure peek-window index selection for map snapshot prefetch (provider-agnostic).
public enum MapSnapshotSchedulingPolicy {
    public static func peekIndices(
        centerIndex: Int,
        cardCount: Int,
        peekRadius: Int = GeoKitMapCardStageConstants.peekRadius,
        previousCenterIndex: Int? = nil
    ) -> [(index: Int, peekDistance: Int, force: Bool)] {
        CardMediaPeekScheduling.peekIndices(
            centerIndex: centerIndex,
            cardCount: cardCount,
            peekRadius: peekRadius,
            previousCenterIndex: previousCenterIndex
        )
    }
}
