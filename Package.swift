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
        .library(name: "GeoKit", type: .dynamic, targets: ["GeoKit"]),
    ],
    dependencies: [
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
            name: "GeoKit",
            dependencies: ["GeoKitCore", "GeoKitContract"]
        ),
        .testTarget(
            name: "GeoKitCoreTests",
            dependencies: ["GeoKitCore"],
            resources: [.process("Fixtures")]
        ),
    ]
)
