import GeoKitCore
import XCTest

final class GeoKitColorTests: XCTestCase {
    func testHslToHexGray() {
        XCTAssertEqual(GeoKitColor.hslToHex(h: 0, s: 0, l: 46.7), "#777777")
    }

    func testHexToHslGray() {
        let hsl = GeoKitColor.hexToHSL("#777777")
        XCTAssertEqual(hsl.h, 0, accuracy: 1)
        XCTAssertEqual(hsl.s, 0, accuracy: 1)
        XCTAssertEqual(hsl.l, 46.7, accuracy: 1)
    }

    func testHexToRGB() {
        XCTAssertEqual(GeoKitColor.hexToRGB("#ff8040"), GeoKitRGB(r: 255, g: 128, b: 64))
    }

    func testPaletteCycler() {
        let cycler = GeoKitPaletteCycler(palette: ["#111111", "#222222", "#333333"])
        var seen = Set<String>()
        seen.insert(cycler.next())
        seen.insert(cycler.next())
        seen.insert(cycler.next())
        XCTAssertEqual(seen.count, 3)
    }
}
