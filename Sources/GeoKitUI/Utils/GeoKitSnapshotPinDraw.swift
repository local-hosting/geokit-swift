#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

import CoreLocation
import GeoKitContract
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Draws peek snapshot pin markers onto a static map image (Mapbox overlay or MapKit composite).
public enum GeoKitSnapshotPinDraw {
    private static let dotDiameter: CGFloat = 14
    /// Matches ``GeoKitPlacePinView`` bottom-anchor lift for the collapsed dot fallback.
    private static let anchorLift: CGFloat = 16

    public static func draw(
        pins: [MapPin],
        in context: CGContext,
        pointForCoordinate: (CLLocationCoordinate2D) -> CGPoint,
        selectedPinId: UUID?,
        zoom: Double,
        scale: CGFloat,
        renderPinImages: Bool = true
    ) {
        guard !pins.isEmpty else { return }
        let pinZoom = CGFloat(zoom)
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
            let selected = pin.id == selectedPinId
            if renderPinImages {
                if let image = renderPinImageOnMainActor(
                    for: pin,
                    coordinate: coordinate,
                    selected: selected,
                    zoom: pinZoom,
                    scale: scale
                ) {
                    drawPinImage(image, anchor: anchor)
                } else {
                    drawDot(in: context, pin: pin, anchor: anchor, scale: scale)
                }
            } else {
                drawDot(in: context, pin: pin, anchor: anchor, scale: scale)
            }
        }
    }

    public static func composite(
        baseImage: GeoKitPlatformImage,
        pins: [MapPin],
        pointForCoordinate: (CLLocationCoordinate2D) -> CGPoint,
        selectedPinId: UUID?,
        zoom: Double,
        renderPinImages: Bool = true
    ) -> GeoKitPlatformImage {
        guard !pins.isEmpty else { return baseImage }
        #if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat()
        format.scale = baseImage.geoKitScale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: baseImage.size, format: format)
        return renderer.image { rendererContext in
            baseImage.draw(at: .zero)
            draw(
                pins: pins,
                in: rendererContext.cgContext,
                pointForCoordinate: pointForCoordinate,
                selectedPinId: selectedPinId,
                zoom: zoom,
                scale: baseImage.geoKitScale,
                renderPinImages: renderPinImages
            )
        }
        #elseif canImport(AppKit)
        let size = baseImage.size
        let scale = baseImage.geoKitScale
        let composed = NSImage(size: size)
        composed.lockFocusFlipped(true)
        baseImage.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        if let context = NSGraphicsContext.current?.cgContext {
            draw(
                pins: pins,
                in: context,
                pointForCoordinate: pointForCoordinate,
                selectedPinId: selectedPinId,
                zoom: zoom,
                scale: scale,
                renderPinImages: renderPinImages
            )
        }
        composed.unlockFocus()
        return composed
        #endif
    }


    private static func renderPinImageOnMainActor(
        for pin: MapPin,
        coordinate: CLLocationCoordinate2D,
        selected: Bool,
        zoom: CGFloat,
        scale: CGFloat
    ) -> GeoKitPlatformImage? {
        guard Thread.isMainThread else { return nil }
        return MainActor.assumeIsolated {
            renderPinImage(for: pin, coordinate: coordinate, selected: selected, zoom: zoom, scale: scale)
        }
    }

    @MainActor
    private static func renderPinImage(
        for pin: MapPin,
        coordinate: CLLocationCoordinate2D,
        selected: Bool,
        zoom: CGFloat,
        scale: CGFloat
    ) -> GeoKitPlatformImage? {
        let content = GeoKitPlacePinView(
            pin: pin,
            zoom: zoom,
            tap: GeoKitTap(id: pin.id, coordinate: coordinate),
            color: pin.isPrimary ? GeoKitMapTheme.accent : GeoKitMapTheme.secondary,
            onTap: { _, _, _ in },
            selected: selected,
            visible: true,
            allowCallout: true,
            showText: selected
        )
        .environment(\.geokitMapIsTransitioning, true)
        .fixedSize()

        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        #if canImport(UIKit)
        return renderer.uiImage
        #elseif canImport(AppKit)
        return renderer.nsImage
        #endif
    }

    #if canImport(UIKit)
    private static func drawPinImage(_ image: UIImage, anchor: CGPoint) {
        let size = image.size
        let origin = CGPoint(x: anchor.x - size.width / 2, y: anchor.y - size.height)
        image.draw(at: origin)
    }
    #elseif canImport(AppKit)
    private static func drawPinImage(_ image: NSImage, anchor: CGPoint) {
        let size = image.size
        let origin = CGPoint(x: anchor.x - size.width / 2, y: anchor.y - size.height)
        image.draw(at: origin, from: NSRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1.0)
    }
    #endif

    private static func dotFillColor(for pin: MapPin) -> CGColor {
        GeoKitMapTheme.pinFillCGColor(for: pin)
    }

    private static func drawDot(in context: CGContext, pin: MapPin, anchor: CGPoint, scale: CGFloat) {
        let scaledDiameter = dotDiameter * scale
        let lift = anchorLift * scale
        let center = CGPoint(x: anchor.x, y: anchor.y - lift)
        let rect = CGRect(
            x: center.x - scaledDiameter / 2,
            y: center.y - scaledDiameter / 2,
            width: scaledDiameter,
            height: scaledDiameter
        )
        let fill = dotFillColor(for: pin)
        context.setFillColor(fill)
        context.fillEllipse(in: rect)
        context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
        context.setLineWidth(2 * scale)
        context.strokeEllipse(in: rect.insetBy(dx: scale, dy: scale))
    }
}
#endif
