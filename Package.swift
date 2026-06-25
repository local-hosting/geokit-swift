// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GeoKit",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "GeoKitCore", targets: ["GeoKitCore"]),
        .library(name: "GeoKitContract", targets: ["GeoKitContract"]),
        .library(name: "GeoKitUI", targets: ["GeoKitUI"]),
        .library(name: "GeoKit", type: .dynamic, targets: ["GeoKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: "11.25.0"),
        .package(url: "https://github.com/pawelmajcher/SwiftyH3.git", "0.5.0"..<"0.6.0"),
    ],
    targets: [
        .target(
            name: "GeoKitCore",
            dependencies: [
                .product(name: "SwiftyH3", package: "SwiftyH3"),
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
    ]
)
