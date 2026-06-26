#if os(iOS)
import CoreLocation
import GeoKitContract
import UIKit

/// Draws peek snapshot pin markers onto a static map image (Mapbox overlay or MapKit composite).
enum GeoKitSnapshotPinDraw {
    private static let accent = UIColor(red: 69 / 255, green: 56 / 255, blue: 178 / 255, alpha: 1)
    private static let dotDiameter: CGFloat = 14
    private static let selectedScale: CGFloat = 1.15
    /// Matches ``GeoKitPlacePinView`` bottom-anchor lift for the collapsed dot.
    private static let anchorLift: CGFloat = 16

    static func draw(
        pins: [MapPin],
        in context: CGContext,
        pointForCoordinate: (CLLocationCoordinate2D) -> CGPoint,
        selectedPinId: UUID?,
        scale: CGFloat
    ) {
        guard !pins.isEmpty else { return }
        let ordered = pins.sorted { lhs, rhs in
            switch (lhs.id == selectedPinId, rhs.id == selectedPinId) {
            case (true, false): return false
            case (false, true): return true
            default: return true
            }
        }
        for pin in ordered {
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            let anchor = pointForCoordinate(coordinate)
            let diameter = dotDiameter * (pin.id == selectedPinId ? selectedScale : 1)
            drawDot(in: context, anchor: anchor, diameter: diameter, scale: scale)
        }
    }

    static func composite(
        baseImage: UIImage,
        pins: [MapPin],
        pointForCoordinate: (CLLocationCoordinate2D) -> CGPoint,
        selectedPinId: UUID?
    ) -> UIImage {
        guard !pins.isEmpty else { return baseImage }
        let format = UIGraphicsImageRendererFormat()
        format.scale = baseImage.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: baseImage.size, format: format)
        return renderer.image { rendererContext in
            baseImage.draw(at: .zero)
            draw(
                pins: pins,
                in: rendererContext.cgContext,
                pointForCoordinate: pointForCoordinate,
                selectedPinId: selectedPinId,
                scale: baseImage.scale
            )
        }
    }

    private static func drawDot(
        in context: CGContext,
        anchor: CGPoint,
        diameter: CGFloat,
        scale: CGFloat
    ) {
        let scaledDiameter = diameter * scale
        let lift = anchorLift * scale
        let center = CGPoint(x: anchor.x, y: anchor.y - lift)
        let rect = CGRect(
            x: center.x - scaledDiameter / 2,
            y: center.y - scaledDiameter / 2,
            width: scaledDiameter,
            height: scaledDiameter
        )
        context.setFillColor(accent.cgColor)
        context.fillEllipse(in: rect)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2 * scale)
        context.strokeEllipse(in: rect.insetBy(dx: scale, dy: scale))
    }
}
#endif
