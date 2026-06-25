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
        let path = UIBezierPath.geoKitCalloutPath(
            size: rect.size,
            tailSize: tailSize,
            cornerRadius: cornerRadius,
            anchor: anchor
        )
        return Path(path.cgPath)
    }
}

private extension UIBezierPath {
    static func geoKitCalloutPath(
        size: CGSize,
        tailSize: CGFloat,
        cornerRadius: CGFloat,
        anchor: GeoKitCalloutAnchor
    ) -> UIBezierPath {
        let rect = CGRect(origin: .zero, size: size)
        let bubbleRect = rect.insetBy(dx: tailSize, dy: tailSize)
        let path = UIBezierPath(roundedRect: bubbleRect, cornerRadius: cornerRadius)

        let tailPath = UIBezierPath()
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

        for (index, point) in tailPoints.enumerated() {
            if index == 0 {
                tailPath.move(to: point)
            } else {
                tailPath.addLine(to: point)
            }
        }
        tailPath.close()
        path.append(tailPath)
        return path
    }
}

#if canImport(MapboxMaps)
import MapboxMaps

extension GeoKitCalloutAnchor {
    init(_ anchor: ViewAnnotationAnchor) {
        switch anchor {
        case .topLeft: self = .topLeft
        case .top: self = .top
        case .topRight: self = .topRight
        case .bottomLeft: self = .bottomLeft
        case .bottom: self = .bottom
        case .bottomRight: self = .bottomRight
        case .left: self = .left
        case .right: self = .right
        default: self = .center
        }
    }

    var mapboxAnchor: ViewAnnotationAnchor {
        switch self {
        case .topLeft: return .topLeft
        case .top: return .top
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottom: return .bottom
        case .bottomRight: return .bottomRight
        case .left: return .left
        case .right: return .right
        case .center: return .center
        }
    }
}
#endif
