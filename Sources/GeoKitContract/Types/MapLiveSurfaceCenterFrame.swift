import CoreGraphics
import Foundation

/// Center-anchored live map frame — avoids corner-origin interpolation during expand/collapse.
public struct MapLiveSurfaceCenterFrame: Equatable, Sendable {
    public let centerX: CGFloat
    public let centerY: CGFloat
    public let width: CGFloat
    public let height: CGFloat

    public init(centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat) {
        self.centerX = centerX
        self.centerY = centerY
        self.width = width
        self.height = height
    }

    public init(globalFrame: CGRect) {
        centerX = globalFrame.midX
        centerY = globalFrame.midY
        width = globalFrame.width
        height = globalFrame.height
    }

    public var globalFrame: CGRect {
        CGRect(
            x: centerX - width / 2,
            y: centerY - height / 2,
            width: width,
            height: height
        )
    }
}
