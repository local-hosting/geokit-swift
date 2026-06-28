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
        .library(name: "GeoKitUIAccord", targets: ["GeoKitUIAccord"]),
        .library(name: "GeoKitUIMapbox", targets: ["GeoKitUIMapbox"]),
        .library(name: "GeoKit", type: .dynamic, targets: ["GeoKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: "11.25.0"),
        .package(url: "https://github.com/mapbox/turf-swift.git", from: "4.0.0"),
        .package(url: "https://github.com/pawelmajcher/SwiftyH3.git", "0.5.0" ..< "0.6.0"),
        .package(path: "../../../GitHub/places/Packages/design-system"),
    ],
    targets: [
        .target(
            name: "GeoKitCore",
            dependencies: [
                .product(name: "SwiftyH3", package: "SwiftyH3"),
                .product(name: "Turf", package: "turf-swift"),
            ]
        ),
        .target(
            name: "GeoKitContract",
            dependencies: [
                .product(name: "CardMediaContract", package: "design-system"),
            ]
        ),
        .target(
            name: "GeoKitUI",
            dependencies: ["GeoKitContract"]
        ),
        .target(
            name: "GeoKitUIAccord",
            dependencies: [
                "GeoKitUI",
                "GeoKitContract",
                .product(name: "CardMediaContract", package: "design-system"),
                .product(name: "AccordDesignSystem", package: "design-system"),
            ]
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
                "GeoKitUIAccord",
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
