// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GeoKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "GeoKitCore", targets: ["GeoKitCore"]),
        .library(name: "GeoKitContract", targets: ["GeoKitContract"]),
        .library(name: "GeoKitUI", targets: ["GeoKitUI"]),
        .library(name: "GeoKit", type: .dynamic, targets: ["GeoKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: "11.25.0"),
        .package(url: "https://github.com/mapbox/turf-swift.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "Ch3",
            path: "Vendor/SwiftyH3/Sources/Ch3",
            publicHeadersPath: "include"
        ),
        .target(
            name: "GeoKitCore",
            dependencies: [
                "Ch3",
                .product(name: "Turf", package: "turf-swift"),
            ]
        ),
        .target(
            name: "GeoKitContract",
            dependencies: ["GeoKitCore"]
        ),
        .target(
            name: "GeoKitUI",
            dependencies: [
                "GeoKitCore",
                "GeoKitContract",
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
            ]
        ),
        .target(
            name: "GeoKit",
            dependencies: [
                "GeoKitCore",
                "GeoKitContract",
                "GeoKitUI",
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
    ]
)
