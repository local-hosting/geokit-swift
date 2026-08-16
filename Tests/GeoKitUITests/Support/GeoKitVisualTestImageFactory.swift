#if os(iOS) || os(macOS)

import CoreGraphics
import GeoKitUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum GeoKitVisualTestImageFactory {
    static let canvasSize = CGSize(width: 240, height: 160)
    static let renderScale: CGFloat = 2

    static func solidBaseImage(
        size: CGSize = canvasSize,
        color: CGColor = CGColor(srgbRed: 0.88, green: 0.91, blue: 0.95, alpha: 1)
    ) -> GeoKitPlatformImage {
        #if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat()
        format.scale = renderScale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            context.cgContext.setFillColor(color)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
        }
        #elseif canImport(AppKit)
        let image = NSImage(size: size)
        image.lockFocusFlipped(true)
        NSColor(cgColor: color)?.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
        #endif
    }

    static func pngData(from image: GeoKitPlatformImage) -> Data? {
        #if canImport(UIKit)
        return image.pngData()
        #elseif canImport(AppKit)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return rep.representation(using: .png, properties: [:])
        #endif
    }

    static func decodePNG(_ data: Data) -> GeoKitPlatformImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #endif
    }
}

#endif
