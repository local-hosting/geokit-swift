import Foundation

public enum Easing {
    public static func easeInOutCubic(_ value: Double) -> Double {
        let clamped = max(0, min(1, value))
        if clamped < 0.5 {
            return 4 * clamped * clamped * clamped
        }
        return 1 - pow(-2 * clamped + 2, 3) / 2
    }

    public static func easeLinear(_ value: Double) -> Double {
        max(0, min(1, value))
    }
}
