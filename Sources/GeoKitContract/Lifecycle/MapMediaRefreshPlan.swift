import CardMediaContract
import Foundation

public typealias MapMediaRefreshPlan = CardMediaRefreshPlan

public enum MapMediaRefreshPlanner {
    public static func plan(
        centerIndex: Int,
        cardCount: Int,
        peekRadius: Int,
        layoutReady: Bool,
        centerHasSnapshot: Bool,
        fanHasSnapshot: (Int) -> Bool
    ) -> MapMediaRefreshPlan {
        CardMediaRefreshPlanner.plan(
            centerIndex: centerIndex,
            cardCount: cardCount,
            peekRadius: peekRadius,
            layoutReady: layoutReady,
            centerHasSnapshot: centerHasSnapshot,
            fanHasSnapshot: fanHasSnapshot
        )
    }
}
