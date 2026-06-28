import CoreGraphics
import Foundation

/// Map capture/live map size — full card content; footer badge floats above (Accord ``AXCard``).
public enum MapMediaSurfaceLayout {
    public static func mapContentSize(
        cardContentSize: CGSize,
        mediaSurfaceFooterInset footerInset: CGFloat = 0
    ) -> CGSize {
        _ = footerInset
        return cardContentSize
    }
}
