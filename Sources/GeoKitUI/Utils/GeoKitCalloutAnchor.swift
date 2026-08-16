import SwiftUI

/// Provider-agnostic callout tail anchor (decoupled from Mapbox `ViewAnnotationAnchor`).
public enum GeoKitCalloutAnchor: Sendable, Equatable {
    case topLeft
    case top
    case topRight
    case bottomLeft
    case bottom
    case bottomRight
    case left
    case right
    case center
}

#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)
extension View {
    func geoKitCallout(
        anchor: GeoKitCalloutAnchor,
        color: Color,
        borderColor: Color,
        tailSize: Double = 8.0,
        cornerRadius: Double = 8,
        borderWidth: CGFloat = 2
    ) -> some View {
        modifier(GeoKitCalloutViewModifier(
            anchor: anchor,
            color: color,
            borderColor: borderColor,
            tailSize: tailSize,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth
        ))
    }
}

private struct GeoKitCalloutViewModifier: ViewModifier {
    var anchor: GeoKitCalloutAnchor
    var color: Color
    var borderColor: Color
    var tailSize: Double
    var cornerRadius: Double
    var borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(tailSize)
            .background(
                GeoKitCalloutShape(anchor: anchor, tailSize: tailSize, cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
                    .fill(color)
                    .shadow(color: Color.black.opacity(0.2), radius: 3)
            )
    }
}

private struct GeoKitCalloutShape: Shape {
    var anchor: GeoKitCalloutAnchor
    var tailSize: CGFloat
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        geoKitCalloutPath(
            size: rect.size,
            tailSize: tailSize,
            cornerRadius: cornerRadius,
            anchor: anchor
        )
    }
}

private func geoKitCalloutPath(
    size: CGSize,
    tailSize: CGFloat,
    cornerRadius: CGFloat,
    anchor: GeoKitCalloutAnchor
) -> Path {
    let rect = CGRect(origin: .zero, size: size)
    let bubbleRect = rect.insetBy(dx: tailSize, dy: tailSize)
    var path = Path(roundedRect: bubbleRect, cornerRadius: cornerRadius)

    let p = tailSize
    let h = size.height
    let w = size.width
    let r = cornerRadius
    let tailPoints: [CGPoint]
    switch anchor {
    case .topLeft:
        tailPoints = [CGPoint(x: 0, y: 0), CGPoint(x: p + r, y: p), CGPoint(x: p, y: p + r)]
    case .top:
        tailPoints = [CGPoint(x: w / 2, y: 0), CGPoint(x: w / 2 - p, y: p), CGPoint(x: w / 2 + p, y: p)]
    case .topRight:
        tailPoints = [CGPoint(x: w, y: 0), CGPoint(x: w - p, y: p + r), CGPoint(x: w - 3 * p, y: p)]
    case .bottomLeft:
        tailPoints = [CGPoint(x: 0, y: h), CGPoint(x: p, y: h - (p + r)), CGPoint(x: p + r, y: h - p)]
    case .bottom:
        tailPoints = [CGPoint(x: w / 2, y: h), CGPoint(x: w / 2 - p / 1.3, y: h - p), CGPoint(x: w / 2 + p / 1.3, y: h - p)]
    case .bottomRight:
        tailPoints = [CGPoint(x: w, y: h), CGPoint(x: w - (p + r), y: h - p), CGPoint(x: w - p, y: h - (p + r))]
    case .left:
        tailPoints = [CGPoint(x: 0, y: h / 2), CGPoint(x: p, y: h / 2 - p), CGPoint(x: p, y: h / 2 + p)]
    case .right:
        tailPoints = [CGPoint(x: w, y: h / 2), CGPoint(x: w - p, y: h / 2 - p), CGPoint(x: w - p, y: h / 2 + p)]
    case .center:
        tailPoints = [CGPoint(x: w / 2, y: h), CGPoint(x: w / 2 - p, y: h - p), CGPoint(x: w / 2 + p, y: h - p)]
    }

    var tailPath = Path()
    for (index, point) in tailPoints.enumerated() {
        if index == 0 {
            tailPath.move(to: point)
        } else {
            tailPath.addLine(to: point)
        }
    }
    tailPath.closeSubpath()
    path.addPath(tailPath)
    return path
}
#endif
