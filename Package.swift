// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GeoKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "GeoKitCore", targets: ["GeoKitCore"]),
        .library(name: "GeoKitContract", targets: ["GeoKitContract"]),
        .library(name: "GeoKitUI", targets: ["GeoKitUI", "GeoKitContract"]),
        .library(name: "GeoKitUIMapbox", targets: ["GeoKitUIMapbox"]),
        .library(name: "GeoKit", type: .dynamic, targets: ["GeoKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: "11.25.0"),
        .package(url: "https://github.com/mapbox/turf-swift.git", from: "4.0.0"),
    ],
    targets: [
        // Uber H3 (v4.4.1) as a prebuilt binary so no C source target is compiled —
        // avoids the Xcode 26 explicit-clang-modules failure for SPM C targets.
        .binaryTarget(
            name: "Ch3",
            path: "Vendor/Ch3.xcframework"
        ),
        .target(
            name: "GeoKitCore",
            dependencies: [
                "Ch3",
                .product(name: "Turf", package: "turf-swift"),
            ]
        ),
        .target(
            name: "GeoKitContract"
        ),
        .target(
            name: "GeoKitUI",
            dependencies: ["GeoKitContract", "GeoKitCore"]
        ),
        .target(
            name: "GeoKitUIMapbox",
            dependencies: [
                "GeoKitUI",
                .product(name: "MapboxMaps", package: "mapbox-maps-ios", condition: .when(platforms: [.iOS])),
            ]
        ),
        .target(
            name: "GeoKit",
            dependencies: [
                "GeoKitCore",
                "GeoKitContract",
                "GeoKitUI",
                "GeoKitUIMapbox",
            ]
        ),
        .testTarget(
            name: "GeoKitCoreTests",
            dependencies: ["GeoKitCore"],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "GeoKitContractTests",
            dependencies: ["GeoKitContract"]
        ),
        .testTarget(
            name: "GeoKitUITests",
            dependencies: ["GeoKitUI", "GeoKitContract"]
        ),
    ]
)
