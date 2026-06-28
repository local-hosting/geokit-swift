#if canImport(UIKit)
import UIKit

/// Bitmap image type for GeoKit peek snapshots — `UIImage` on iOS.
public typealias GeoKitPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit

/// Bitmap image type for GeoKit peek snapshots — `NSImage` on macOS (test/host builds).
public typealias GeoKitPlatformImage = NSImage
#endif
