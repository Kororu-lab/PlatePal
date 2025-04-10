// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PlatePal",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "PlatePal",
            targets: ["PlatePal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/naver/maps-ios-sdk.git", from: "3.16.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "PlatePal",
            dependencies: [
                .product(name: "NMapsMap", package: "maps-ios-sdk")
            ]),
        .testTarget(
            name: "PlatePalTests",
            dependencies: ["PlatePal"]
        ),
    ]
)
