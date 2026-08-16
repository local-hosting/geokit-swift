import Foundation

/// When a hoisted root host paints live tiles, the card hole may show a snapshot cover until the first live frame.
public enum MapHoistedLiveCoverPolicy {
    /// True while the live surface has not painted — caller supplies the snapshot bitmap when available.
    public static func showsTransitionCover(isMapRendered: Bool) -> Bool {
        MapPinTransitionCoverPolicy.coversLiveSurface(livePainted: isMapRendered)
    }
}
