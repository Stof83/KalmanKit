// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KalmanKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7),
        .macCatalyst(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "KalmanKit", targets: ["KalmanKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Jounce/Surge", .upToNextMajor(from: "2.3.2")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "KalmanKit",
            dependencies: [
                .product(name: "Surge", package: "Surge"),
            ]
        ),
        .testTarget(
            name: "KalmanKitTests",
            dependencies: ["KalmanKit"]
        ),
    ]
)
