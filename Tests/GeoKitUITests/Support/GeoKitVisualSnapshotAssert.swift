#if os(iOS) || os(macOS)

@testable import GeoKitUI
import XCTest

enum GeoKitVisualSnapshotAssert {
    private static let recordVisuals = ProcessInfo.processInfo.environment["GEOKIT_RECORD_VISUALS"] == "1"
    private static let maxChannelDelta: UInt8 = 4
    private static let minimumMatchingPixelRatio = 0.985

    static func assertSnapshot(
        _ image: GeoKitPlatformImage,
        named name: String,
        testCase: XCTestCase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let platform = platformSuffix
        let resourceName = "\(name)-\(platform)"

        guard let actualPNG = GeoKitVisualTestImageFactory.pngData(from: image) else {
            XCTFail("Could not encode snapshot PNG for \(resourceName)", file: file, line: line)
            return
        }

        if recordVisuals {
            let destination = sourceFixtureURL(resourceName: resourceName)
            do {
                try FileManager.default.createDirectory(
                    at: destination.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try actualPNG.write(to: destination)
                fputs("[GeoKitVisualSnapshotAssert] recorded \(destination.path)\n", stderr)
            } catch {
                XCTFail("Failed to record \(resourceName): \(error)", file: file, line: line)
            }
            return
        }

        guard let referenceURL = Bundle.module.url(
            forResource: resourceName,
            withExtension: "png"
        ) else {
            XCTFail(
                "Missing reference PNG \(resourceName).png — run with GEOKIT_RECORD_VISUALS=1",
                file: file,
                line: line
            )
            return
        }

        guard let expectedPNG = try? Data(contentsOf: referenceURL) else {
            XCTFail("Could not read reference PNG at \(referenceURL.path)", file: file, line: line)
            return
        }

        guard let expectedImage = GeoKitVisualTestImageFactory.decodePNG(expectedPNG),
              let actualImage = GeoKitVisualTestImageFactory.decodePNG(actualPNG) else {
            XCTFail("Could not decode PNG for \(resourceName)", file: file, line: line)
            return
        }

        let comparison = compare(expectedImage, actualImage)
        guard comparison.matchRatio >= minimumMatchingPixelRatio else {
            attachArtifacts(
                testCase: testCase,
                name: resourceName,
                expected: expectedPNG,
                actual: actualPNG,
                diff: comparison.diffPNG,
                matchRatio: comparison.matchRatio
            )
            XCTFail(
                "Visual mismatch for \(resourceName): \(String(format: "%.2f%%", comparison.matchRatio * 100)) pixels matched (need \(minimumMatchingPixelRatio * 100)%).",
                file: file,
                line: line
            )
            return
        }
    }

    private static var platformSuffix: String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #else
        return "unknown"
        #endif
    }

    private static func sourceFixtureURL(resourceName: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/Visual/\(resourceName).png")
    }

    private static func compare(
        _ expected: GeoKitPlatformImage,
        _ actual: GeoKitPlatformImage
    ) -> (matchRatio: Double, diffPNG: Data?) {
        guard let expectedCG = expected.geoKitCGImage,
              let actualCG = actual.geoKitCGImage else {
            return (0, nil)
        }

        let width = min(expectedCG.width, actualCG.width)
        let height = min(expectedCG.height, actualCG.height)
        guard width > 0, height > 0 else { return (0, nil) }

        var expectedBytes = [UInt8](repeating: 0, count: width * height * 4)
        var actualBytes = [UInt8](repeating: 0, count: width * height * 4)
        var diffBytes = [UInt8](repeating: 0, count: width * height * 4)

        guard let expectedContext = rgbaContext(from: expectedCG, width: width, height: height, buffer: &expectedBytes),
              let actualContext = rgbaContext(from: actualCG, width: width, height: height, buffer: &actualBytes) else {
            return (0, nil)
        }
        _ = expectedContext
        _ = actualContext

        var matching = 0
        let pixelCount = width * height
        for index in 0..<pixelCount {
            let offset = index * 4
            if channelsMatch(
                expected: expectedBytes,
                actual: actualBytes,
                offset: offset,
                maxDelta: maxChannelDelta
            ) {
                matching += 1
                diffBytes[offset] = expectedBytes[offset]
                diffBytes[offset + 1] = expectedBytes[offset + 1]
                diffBytes[offset + 2] = expectedBytes[offset + 2]
                diffBytes[offset + 3] = expectedBytes[offset + 3]
            } else {
                diffBytes[offset] = 255
                diffBytes[offset + 1] = 0
                diffBytes[offset + 2] = 255
                diffBytes[offset + 3] = 255
            }
        }

        let diffPNG = pngData(from: diffBytes, width: width, height: height)
        return (Double(matching) / Double(pixelCount), diffPNG)
    }

    private static func rgbaContext(
        from image: CGImage,
        width: Int,
        height: Int,
        buffer: inout [UInt8]
    ) -> CGContext? {
        let context = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context
    }

    private static func pngData(from rgba: [UInt8], width: Int, height: Int) -> Data? {
        var mutable = rgba
        guard let context = CGContext(
            data: &mutable,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cgImage = context.makeImage() else {
            return nil
        }
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage).pngData()
        #elseif canImport(AppKit)
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .png, properties: [:])
        #endif
    }


    private static func channelsMatch(
        expected: [UInt8],
        actual: [UInt8],
        offset: Int,
        maxDelta: UInt8
    ) -> Bool {
        for channel in 0..<4 {
            let delta = abs(Int(expected[offset + channel]) - Int(actual[offset + channel]))
            if delta > maxDelta {
                return false
            }
        }
        return true
    }

    private static func attachArtifacts(
        testCase: XCTestCase,
        name: String,
        expected: Data,
        actual: Data,
        diff: Data?,
        matchRatio: Double
    ) {
        let expectedAttachment = XCTAttachment(data: expected, uniformTypeIdentifier: "public.png")
        expectedAttachment.name = "\(name)-expected"
        testCase.add(expectedAttachment)

        let actualAttachment = XCTAttachment(data: actual, uniformTypeIdentifier: "public.png")
        actualAttachment.name = "\(name)-actual"
        testCase.add(actualAttachment)

        if let diff {
            let diffAttachment = XCTAttachment(data: diff, uniformTypeIdentifier: "public.png")
            diffAttachment.name = "\(name)-diff-\(String(format: "%.1f", matchRatio * 100))pct"
            testCase.add(diffAttachment)
        }
    }
}

#endif
