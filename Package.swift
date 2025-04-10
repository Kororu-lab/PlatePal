// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Note: This Package.swift is primarily used for development purposes. 
// For actual builds, use the Xcode project and CocoaPods.

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
        // No external dependencies required - they're handled by CocoaPods
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Main app target
        .executableTarget(
            name: "PlatePal",
            path: "Sources",
            exclude: ["Info.plist", "Resources/LaunchScreen.storyboard"], // Exclude files that might cause issues
            resources: [
                .process("Resources")
            ]
        )
    ]
)
