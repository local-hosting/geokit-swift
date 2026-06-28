import CardMediaContract
import CoreGraphics
import Foundation

public extension CardDragWarmLivePolicy {
    static func warmTargetIndex(
        layout: GeoKitCardMapCollectionLayout,
        cardCount: Int,
        centerIndex: Int,
        dragOffset: CGFloat,
        threshold: CGFloat
    ) -> Int? {
        guard cardCount > 1 else { return nil }
        switch layout {
        case .scroll:
            return nil
        case .stack:
            return stackWarmTargetIndex(cardCount: cardCount, dragOffset: dragOffset, threshold: threshold)
        case .deck:
            return deckWarmTargetIndex(
                cardCount: cardCount,
                centerIndex: centerIndex,
                dragOffset: dragOffset,
                threshold: threshold
            )
        }
    }

    static func stackWarmTargetIndex(
        cardCount: Int,
        dragOffset: CGFloat,
        threshold: CGFloat
    ) -> Int? {
        warmTargetIndex(cardCount: cardCount, dragOffset: dragOffset, threshold: threshold)
    }

    static func deckWarmTargetIndex(
        cardCount: Int,
        centerIndex: Int,
        dragOffset: CGFloat,
        threshold: CGFloat
    ) -> Int? {
        guard cardCount > 1, (0..<cardCount).contains(centerIndex) else { return nil }
        if dragOffset <= -threshold, centerIndex + 1 < cardCount {
            return centerIndex + 1
        }
        if dragOffset >= threshold, centerIndex > 0 {
            return centerIndex - 1
        }
        return nil
    }
}
