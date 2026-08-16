import SwiftUI

#if canImport(UIKit)
import UIKit

/// Bitmap image type for GeoKit peek snapshots.
public typealias GeoKitPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit

/// Bitmap image type for GeoKit peek snapshots.
public typealias GeoKitPlatformImage = NSImage
#endif

extension Image {
    /// Cross-platform bridge from a ``GeoKitPlatformImage`` (`UIImage` or `NSImage`).
    init(geoKitImage image: GeoKitPlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: image)
        #elseif canImport(AppKit)
        self.init(nsImage: image)
        #endif
    }
}

extension GeoKitPlatformImage {
    /// Backing `CGImage`, used when compositing pins onto a snapshot via Core Graphics.
    var geoKitCGImage: CGImage? {
        #if canImport(UIKit)
        return cgImage
        #elseif canImport(AppKit)
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #endif
    }

    /// Pixel scale of the image; `NSImage` is point-based so macOS reports `1`.
    var geoKitScale: CGFloat {
        #if canImport(UIKit)
        return scale
        #else
        return 1
        #endif
    }
}
