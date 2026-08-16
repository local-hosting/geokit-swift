import Foundation

public struct GeoKitRGB: Equatable, Sendable {
    public let r: Int
    public let g: Int
    public let b: Int

    public init(r: Int, g: Int, b: Int) {
        self.r = r
        self.g = g
        self.b = b
    }
}

public struct GeoKitHSL: Equatable, Sendable {
    public let h: Double
    public let s: Double
    public let l: Double

    public init(h: Double, s: Double, l: Double) {
        self.h = h
        self.s = s
        self.l = l
    }
}

public enum GeoKitColor {
    public static func hslToHex(h: Double, s: Double, l: Double) -> String {
        let saturation = s / 100
        let lightness = l / 100
        let k = { (n: Double) -> Double in
            (n + h / 30).truncatingRemainder(dividingBy: 12)
        }
        let a = saturation * min(lightness, 1 - lightness)
        let f = { (n: Double) -> Double in
            lightness - a * max(-1, min(k(n) - 3, min(9 - k(n), 1)))
        }
        let toHex = { (channel: Double) -> String in
            let hex = String(Int((channel * 255).rounded()), radix: 16)
            return hex.count == 1 ? "0\(hex)" : hex
        }
        return "#\(toHex(f(0)))\(toHex(f(8)))\(toHex(f(4)))"
    }

    public static func hexToHSL(_ hex: String) -> GeoKitHSL {
        guard !hex.isEmpty else {
            return GeoKitHSL(h: 0, s: 0, l: 0)
        }

        let normalized = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var r = 0.0
        var g = 0.0
        var b = 0.0

        if normalized.count == 3 {
            let chars = Array(normalized)
            r = Double(Int(String(repeating: chars[0], count: 2), radix: 16) ?? 0) / 255
            g = Double(Int(String(repeating: chars[1], count: 2), radix: 16) ?? 0) / 255
            b = Double(Int(String(repeating: chars[2], count: 2), radix: 16) ?? 0) / 255
        } else if normalized.count == 6 {
            r = Double(Int(normalized.prefix(2), radix: 16) ?? 0) / 255
            g = Double(Int(normalized.dropFirst(2).prefix(2), radix: 16) ?? 0) / 255
            b = Double(Int(normalized.suffix(2), radix: 16) ?? 0) / 255
        } else {
            return GeoKitHSL(h: 0, s: 0, l: 0)
        }

        let maxValue = max(r, g, b)
        let minValue = min(r, g, b)
        var hue = 0.0
        var saturation = 0.0
        let lightness = (maxValue + minValue) / 2

        if maxValue != minValue {
            let delta = maxValue - minValue
            saturation = lightness > 0.5 ? delta / (2 - maxValue - minValue) : delta / (maxValue + minValue)
            switch maxValue {
            case r:
                hue = (g - b) / delta + (g < b ? 6 : 0)
            case g:
                hue = (b - r) / delta + 2
            default:
                hue = (r - g) / delta + 4
            }
            hue /= 6
        }

        return GeoKitHSL(h: hue * 360, s: saturation * 100, l: lightness * 100)
    }

    public static func hexToRGB(_ hex: String, fallback: GeoKitRGB = GeoKitRGB(r: 136, g: 136, b: 136)) -> GeoKitRGB {
        guard !hex.isEmpty else { return fallback }

        var normalized = hex
        if normalized.count == 4, normalized.hasPrefix("#") {
            let chars = Array(normalized.dropFirst())
            if chars.count == 3 {
                normalized = "#\(chars[0])\(chars[0])\(chars[1])\(chars[1])\(chars[2])\(chars[2])"
            }
        }

        let stripped = normalized.hasPrefix("#") ? String(normalized.dropFirst()) : normalized
        guard stripped.count == 6,
              let r = Int(stripped.prefix(2), radix: 16),
              let g = Int(stripped.dropFirst(2).prefix(2), radix: 16),
              let b = Int(stripped.suffix(2), radix: 16) else {
            return fallback
        }

        return GeoKitRGB(r: r, g: g, b: b)
    }
}

public final class GeoKitPaletteCycler: @unchecked Sendable {
    private let palette: [String]
    private let fallback: String
    private var available: [String]

    public init(palette: [String], fallback: String = "#777777") {
        self.palette = palette
        self.fallback = fallback
        self.available = palette
    }

    public func next() -> String {
        if available.isEmpty {
            reset()
        }
        guard !available.isEmpty else { return fallback }
        let index = Int.random(in: 0..<available.count)
        return available.remove(at: index)
    }

    public func reset() {
        available = palette
    }
}
