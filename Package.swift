// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GeoKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "GeoKitCore", targets: ["GeoKitCore"]),
        .library(name: "GeoKitContract", targets: ["GeoKitContract"]),
        .library(name: "GeoKitUI", targets: ["GeoKitUI"]),
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
            name: "GeoKitCh3",
            path: "Vendor/Ch3.xcframework"
        ),
        .target(
            name: "GeoKitCore",
            dependencies: [
                .target(name: "GeoKitCh3", condition: .when(platforms: [.iOS, .macOS])),
                .product(name: "Turf", package: "turf-swift"),
            ]
        ),
        .target(
            name: "GeoKitContract"
        ),
        .target(
            name: "GeoKitUI",
            dependencies: [
                .target(name: "GeoKitContract"),
            ]
        ),
        .target(
            name: "GeoKitUIMapbox",
            dependencies: [
                .target(name: "GeoKitContract"),
                .target(name: "GeoKitUI"),
                .product(name: "MapboxMaps", package: "mapbox-maps-ios", condition: .when(platforms: [.iOS, .visionOS])),
            ]
        ),
        .target(
            name: "GeoKit",
            dependencies: [
                "GeoKitCore",
                "GeoKitContract",
                "GeoKitUI",
                .target(name: "GeoKitUIMapbox", condition: .when(platforms: [.iOS, .visionOS])),
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
            dependencies: ["GeoKitUI", "GeoKitContract"],
            resources: [.process("Fixtures")]
        ),
    ]
)
