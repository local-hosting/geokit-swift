#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

import GeoKitContract
import SwiftUI

private struct GeoKitCenterAnchoredGlobalFrameModifier: AnimatableModifier {
    var centerX: CGFloat
    var centerY: CGFloat
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat
    let localOrigin: CGPoint

    var animatableData: AnimatablePair<
        AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>,
        CGFloat
    > {
        get {
            AnimatablePair(
                AnimatablePair(
                    AnimatablePair(centerX, centerY),
                    AnimatablePair(width, height)
                ),
                cornerRadius
            )
        }
        set {
            centerX = newValue.first.first.first
            centerY = newValue.first.first.second
            width = newValue.first.second.first
            height = newValue.first.second.second
            cornerRadius = newValue.second
        }
    }

    func body(content: Content) -> some View {
        let originX = centerX - width / 2
        let originY = centerY - height / 2
        content
            .frame(width: max(0, width), height: max(0, height))
            .clipShape(RoundedRectangle(cornerRadius: max(0, cornerRadius), style: .continuous))
            .compositingGroup()
            .offset(x: originX - localOrigin.x, y: originY - localOrigin.y)
    }
}

public extension View {
    /// Positions content by global center + size with a rounded mask (App Store–style expand).
    func geokitCenterAnchoredGlobalFrame(
        _ frame: MapLiveSurfaceCenterFrame,
        localOrigin: CGPoint,
        cornerRadius: CGFloat
    ) -> some View {
        modifier(
            GeoKitCenterAnchoredGlobalFrameModifier(
                centerX: frame.centerX,
                centerY: frame.centerY,
                width: frame.width,
                height: frame.height,
                cornerRadius: cornerRadius,
                localOrigin: localOrigin
            )
        )
    }
}
#endif
