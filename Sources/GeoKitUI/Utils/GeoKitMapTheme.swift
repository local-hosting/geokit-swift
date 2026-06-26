import SwiftUI
import UIKit

public enum GeoKitMapTheme {
    public static let accent = Color(red: 69 / 255, green: 56 / 255, blue: 178 / 255)
    static let ink = Color(red: 0 / 255, green: 3 / 255, blue: 31 / 255)
    public static let placeholderBackground = Color(red: 0 / 255, green: 3 / 255, blue: 31 / 255)

    static let placeholderTitleFont = Font.system(size: 15, weight: .semibold)
    static let calloutHeadingFont = Font.system(size: 12, weight: .bold)
    static let calloutSubheadingFont = Font.system(size: 10, weight: .medium)

    static func emphasisFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }
}

enum GeoKitPinIcon {
    static func image(named name: String) -> Image {
        if UIImage(systemName: name) != nil {
            return Image(systemName: name)
        }
        return Image(systemName: "mappin.circle.fill")
    }
}
