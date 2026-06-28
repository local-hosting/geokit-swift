#if os(iOS)
import AccordDesignSystem
import CoreGraphics
import GeoKitContract
import GeoKitUI
import UIKit

public enum GeoKitCardMapLayout {
    /// Map fills the card content area — footer badge is an overlay, not a layout inset.
    public static func mediaMapSize(forCardContentSize size: CGSize) -> CGSize {
        size
    }

    public static func collapsedMapContentSize(
        collapsedCardFrame: CGRect,
        containerWidth: CGFloat
    ) -> CGSize {
        if AX.Layout.isValidCardMediaLayoutSize(collapsedCardFrame.size) {
            return mediaMapSize(forCardContentSize: collapsedCardFrame.size)
        }
        let width = containerWidth > 0 ? containerWidth : UIScreen.main.bounds.width
        let resolved = AX.StackConstants.resolvedCardSize(
            in: CGSize(width: width, height: 10_000)
        )
        return mediaMapSize(forCardContentSize: resolved)
    }
}
#endif
