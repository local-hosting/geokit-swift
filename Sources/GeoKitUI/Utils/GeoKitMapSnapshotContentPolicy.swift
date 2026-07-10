#if canImport(UIKit)
import UIKit

/// Whether a captured map bitmap actually painted tiles — blank GeoKit plates must not block re-capture or peek.
public enum GeoKitMapSnapshotContentPolicy {
    private static let grid = 12

    /// GeoKit GPU Snapshotter can return an empty Metal plate — reject flat captures with no tile signal.
    public static func hasVisibleMapContent(_ image: UIImage) -> Bool {
        guard let pixels = sampleGrid(from: image) else { return false }

        var luminances: [Double] = []
        luminances.reserveCapacity(grid * grid)
        var distinct = 0
        var nearBlack = 0
        let total = grid * grid
        for index in 0..<total {
            let base = index * 4
            let red = Double(pixels[base])
            let green = Double(pixels[base + 1])
            let blue = Double(pixels[base + 2])
            let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
            luminances.append(luminance)
            let isNearBlack = red < 36 && green < 36 && blue < 36
            let isNearWhite = red > 240 && green > 240 && blue > 240
            if isNearBlack { nearBlack += 1 }
            if !isNearBlack && !isNearWhite { distinct += 1 }
        }

        let mean = luminances.reduce(0, +) / Double(luminances.count)
        let variance = luminances.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(luminances.count)
        let distinctFraction = Double(distinct) / Double(total)
        let nearBlackFraction = Double(nearBlack) / Double(total)

        return variance >= 25
            && distinctFraction >= 0.08
            && nearBlackFraction <= 0.85
    }

    /// Mapbox Static Images API and offline cache — night styles are mostly dark; reject only uniform blank plates.
    public static func acceptsPersistedMapBitmap(_ image: UIImage) -> Bool {
        guard let pixels = sampleGrid(from: image) else { return false }

        let total = grid * grid
        var firstRed = -1, firstGreen = -1, firstBlue = -1
        for index in 0..<total {
            let base = index * 4
            let red = Int(pixels[base])
            let green = Int(pixels[base + 1])
            let blue = Int(pixels[base + 2])
            if firstRed < 0 {
                firstRed = red; firstGreen = green; firstBlue = blue
            } else if red != firstRed || green != firstGreen || blue != firstBlue {
                return true
            }
        }
        return false
    }

    public static func acceptsCapturedBitmap(_ image: UIImage, fromStaticImageService: Bool) -> Bool {
        fromStaticImageService
            ? acceptsPersistedMapBitmap(image)
            : hasVisibleMapContent(image)
    }


    /// Trailing band fraction probed for trailing fan-peek snapshots.
    public static let trailingPeekBandFraction: CGFloat = 0.22

    /// Trailing fan peek requires visible tiles in the trailing sliver, not just the full bitmap.
    public static func acceptsTrailingPeekBitmap(_ image: UIImage) -> Bool {
        acceptsPersistedMapBitmap(image)
            && hasVisibleMapContent(image)
            && trailingPeekSliverHasVisibleContent(image)
    }

    public static func trailingPeekDisplaySnapshot(from image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage, let crop = trailingPeekSliverRect(for: cgImage) else { return image }
        guard let cropped = cgImage.cropping(to: crop) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    private static func trailingPeekSliverRect(for cgImage: CGImage) -> CGRect? {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        guard width > 8, height > 8 else { return nil }
        let band = max(4, width * trailingPeekBandFraction)
        return CGRect(x: width - band, y: height * 0.18, width: band, height: height * 0.55).integral
    }

    private static func trailingPeekSliverHasVisibleContent(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage, let crop = trailingPeekSliverRect(for: cgImage) else { return false }
        guard let cropped = cgImage.cropping(to: crop) else { return false }
        return hasVisibleMapContent(UIImage(cgImage: cropped))
    }

    private static func sampleGrid(from image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }
        guard cgImage.width > 4, cgImage.height > 4 else { return nil }

        let bytesPerRow = grid * 4
        var pixels = [UInt8](repeating: 0, count: grid * grid * 4)
        guard let context = CGContext(
            data: &pixels,
            width: grid,
            height: grid,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .none
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: grid, height: grid))
        return pixels
    }
}
#endif
